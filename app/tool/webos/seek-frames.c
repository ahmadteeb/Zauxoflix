#define _POSIX_C_SOURCE 200809L
#include <dlfcn.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <time.h>
#ifdef __ANDROID__
#include <pthread.h>
#endif

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
#include <libswscale/version.h>

// Decode preview frames independently of the fullscreen player. webOS uses
// the system FFmpeg libraries and Android uses the copy shipped with fvp.
#define FORMAT_API(X) \
  X(avformat_alloc_context) X(avformat_open_input) X(avformat_find_stream_info) \
  X(av_find_best_stream) X(av_seek_frame) X(av_read_frame) X(avformat_close_input) \
  X(avformat_version)
#define CODEC_API(X) \
  X(avcodec_find_decoder) X(avcodec_alloc_context3) X(avcodec_parameters_to_context) \
  X(avcodec_open2) X(avcodec_send_packet) X(avcodec_receive_frame) \
  X(avcodec_flush_buffers) X(avcodec_free_context) X(av_packet_alloc) \
  X(av_packet_unref) X(av_packet_free) X(avcodec_version)
#define UTIL_API(X) \
  X(av_frame_alloc) X(av_frame_free) X(av_frame_unref) X(av_frame_ref) \
  X(av_dict_set) X(av_dict_free) X(av_rescale_q) X(av_log_set_level) X(avutil_version)
#define SCALE_API(X) X(sws_getCachedContext) X(sws_scale) X(sws_freeContext) X(swscale_version)

static struct {
#define ENTRY(name) __typeof__(&name) name;
  FORMAT_API(ENTRY) CODEC_API(ENTRY) UTIL_API(ENTRY) SCALE_API(ENTRY)
#undef ENTRY
} api;

static bool load_api(void) {
  void *library;
#define OPEN(name) library = dlopen(name, RTLD_NOW | RTLD_LOCAL); if (!library) return false;
#define LOAD(name) api.name = (__typeof__(api.name))dlsym(library, #name); if (!api.name) return false;
#ifdef __ANDROID__
  OPEN("libffmpeg.so") FORMAT_API(LOAD) CODEC_API(LOAD) UTIL_API(LOAD) SCALE_API(LOAD)
#else
  OPEN("libavformat.so.60") FORMAT_API(LOAD)
  OPEN("libavcodec.so.60") CODEC_API(LOAD)
  OPEN("libavutil.so.58") UTIL_API(LOAD)
  OPEN("libswscale.so.7") SCALE_API(LOAD)
#endif
#undef LOAD
#undef OPEN
  return (api.avformat_version() >> 16) == LIBAVFORMAT_VERSION_MAJOR &&
      (api.avcodec_version() >> 16) == LIBAVCODEC_VERSION_MAJOR &&
      (api.avutil_version() >> 16) == LIBAVUTIL_VERSION_MAJOR &&
      (api.swscale_version() >> 16) == LIBSWSCALE_VERSION_MAJOR;
}

enum { kWidth = 192, kHeight = 108, kFrameCount = 3 };
static const AVRational milliseconds = { 1, 1000 };

typedef struct {
  AVFormatContext *demuxer;
  AVCodecContext *decoder;
  struct SwsContext *scaler;
  AVPacket *packet;
  AVFrame *decoded;
  AVFrame *previous;
  int stream;
  int64_t deadline;
} Reader;

static int64_t clock_ms(void) {
  struct timespec now;
  clock_gettime(CLOCK_MONOTONIC, &now);
  return (int64_t)now.tv_sec * 1000 + now.tv_nsec / 1000000;
}

static int interrupted(void *opaque) {
  return clock_ms() >= ((Reader *)opaque)->deadline;
}

static bool open_reader(Reader *r, const char *source, const char *headers) {
  const bool web = !strncmp(source, "http://", 7) || !strncmp(source, "https://", 8);
  if (!web && source[0] != '/') return false;
  r->deadline = clock_ms() + 3800;
  r->demuxer = api.avformat_alloc_context();
  if (!r->demuxer) return false;
  r->demuxer->interrupt_callback = (AVIOInterruptCB){ interrupted, r };
  AVDictionary *options = NULL;
  api.av_dict_set(&options, "protocol_whitelist", web ? "http,https,tcp,tls,crypto" : "file", 0);
  api.av_dict_set(&options, "tls_verify", "1", 0);
  api.av_dict_set(&options, "rw_timeout", "2700000", 0);
  api.av_dict_set(&options, "http_multiple", "0", 0);
  if (web && headers && *headers) api.av_dict_set(&options, "headers", headers, 0);
  api.av_dict_set(&options, "probesize", "1500000", 0);
  api.av_dict_set(&options, "analyzeduration", "1500000", 0);
  const int opened = api.avformat_open_input(&r->demuxer, source, NULL, &options);
  api.av_dict_free(&options);
  if (opened < 0 || api.avformat_find_stream_info(r->demuxer, NULL) < 0) return false;
  r->stream = api.av_find_best_stream(r->demuxer, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
  if (r->stream < 0) return false;
  for (unsigned int i = 0; i < r->demuxer->nb_streams; ++i) {
    if (i != (unsigned int)r->stream) {
      r->demuxer->streams[i]->discard = AVDISCARD_ALL;
    }
  }
  AVCodecParameters *params = r->demuxer->streams[r->stream]->codecpar;
  const AVCodec *codec = api.avcodec_find_decoder(params->codec_id);
  if (!codec || !(r->decoder = api.avcodec_alloc_context3(codec))) return false;
  if (api.avcodec_parameters_to_context(r->decoder, params) < 0) return false;
  r->decoder->thread_count = 2;
  r->decoder->skip_loop_filter = AVDISCARD_NONREF;
  r->decoder->max_pixels = 4096 * 2304;
  if (api.avcodec_open2(r->decoder, codec, NULL) < 0) return false;
  r->packet = api.av_packet_alloc();
  r->decoded = api.av_frame_alloc();
  r->previous = api.av_frame_alloc();
  return r->packet && r->decoded && r->previous;
}

static void close_reader(Reader *r) {
  if (r->scaler) api.sws_freeContext(r->scaler);
  api.av_frame_free(&r->previous);
  api.av_frame_free(&r->decoded);
  api.av_packet_free(&r->packet);
  api.avcodec_free_context(&r->decoder);
  api.avformat_close_input(&r->demuxer);
}

static bool next_frame(Reader *r, bool *eof) {
  while (!interrupted(r)) {
    int status = api.avcodec_receive_frame(r->decoder, r->decoded);
    if (status >= 0) return true;
    if (status != AVERROR(EAGAIN) || *eof) return false;
    do {
      status = api.av_read_frame(r->demuxer, r->packet);
      if (status < 0 || r->packet->stream_index == r->stream) break;
      api.av_packet_unref(r->packet);
    } while (!interrupted(r));
    if (status < 0) {
      if (status != AVERROR_EOF) return false;
      *eof = true;
    }
    const int sent = api.avcodec_send_packet(r->decoder, *eof ? NULL : r->packet);
    api.av_packet_unref(r->packet);
    if (sent < 0) return false;
  }
  return false;
}

static bool pixels(Reader *r, const AVFrame *frame, unsigned char *output) {
  AVRational par = frame->sample_aspect_ratio;
  const double aspect = (double)frame->width / frame->height *
      (par.num > 0 && par.den > 0 ? (double)par.num / par.den : 1.0);
  const int width = aspect >= (double)kWidth / kHeight ? kWidth : (int)(kHeight * aspect);
  const int height = aspect >= (double)kWidth / kHeight ? (int)(kWidth / aspect) : kHeight;
  if (width <= 0 || height <= 0) return false;
  r->scaler = api.sws_getCachedContext(r->scaler, frame->width, frame->height,
      frame->format, width, height, AV_PIX_FMT_BGR24, SWS_FAST_BILINEAR, NULL, NULL, NULL);
  if (!r->scaler) return false;
  memset(output, 0, kWidth * kHeight * 3);
  uint8_t *dest[4] = { output + (((kHeight - height) / 2) * kWidth + (kWidth - width) / 2) * 3 };
  const int lines[4] = { kWidth * 3 };
  return api.sws_scale(r->scaler, (const uint8_t * const *)frame->data,
      frame->linesize, 0, frame->height, dest, lines) == height;
}

typedef void (*FrameSink)(void *context, int64_t time, const uint8_t *pixels);

static void write_frame(Reader *r, const AVFrame *frame, int64_t time,
                        FrameSink sink, void *context) {
  unsigned char output[kWidth * kHeight * 3 + 64];
  if (time >= 0 && !pixels(r, frame, output)) time = -1;
  sink(context, time, time >= 0 ? output : NULL);
}

static void capture(Reader *r, int64_t target, FrameSink sink, void *context) {
  const int64_t samples[kFrameCount] = { target - 1000, target, target + 1000 };
  const AVStream *stream = r->demuxer->streams[r->stream];
  const int64_t start = r->demuxer->start_time != AV_NOPTS_VALUE
      ? api.av_rescale_q(r->demuxer->start_time, AV_TIME_BASE_Q, stream->time_base)
      : stream->start_time != AV_NOPTS_VALUE ? stream->start_time : 0;
  const int64_t before = samples[0] > 120 ? samples[0] - 120 : 0;
  r->deadline = clock_ms() + 3400;
  bool eof = false;
  int slot = 0;
  int64_t previous_time = -1;
  while (slot < kFrameCount && samples[slot] < 0) {
    write_frame(r, NULL, -1, sink, context);
    ++slot;
  }
  if (api.av_seek_frame(r->demuxer, r->stream,
          start + api.av_rescale_q(before, milliseconds, stream->time_base),
          AVSEEK_FLAG_BACKWARD) >= 0) {
    api.avcodec_flush_buffers(r->decoder);
    while (slot < kFrameCount && next_frame(r, &eof)) {
      const int64_t pts = r->decoded->best_effort_timestamp;
      if (pts == AV_NOPTS_VALUE) {
        api.av_frame_unref(r->decoded);
        continue;
      }
      int64_t time = api.av_rescale_q(pts - start, stream->time_base, milliseconds);
      if (time < 0) time = 0;
      while (slot < kFrameCount && time >= samples[slot]) {
        if (time == samples[slot] ||
            (previous_time < 0 && time - samples[slot] <= 120)) {
          write_frame(r, r->decoded, time, sink, context);
        } else {
          write_frame(r, r->previous, previous_time, sink, context);
        }
        ++slot;
      }
      api.av_frame_unref(r->previous);
      previous_time = api.av_frame_ref(r->previous, r->decoded) >= 0 ? time : -1;
      api.av_frame_unref(r->decoded);
    }
  }
  // At EOF the last frame may still cover the requested time. On a stall or
  // beyond the end of the title leave the remaining slots empty.
  const int64_t duration = r->demuxer->duration / 1000;
  for (; slot < kFrameCount; ++slot) {
    const bool end_frame = eof && previous_time >= 0 &&
        samples[slot] - previous_time <= 250 &&
        (duration <= 0 || samples[slot] < duration);
    write_frame(r, r->previous, end_frame ? previous_time : -1, sink, context);
  }
  api.av_frame_unref(r->previous);
}

#ifdef __ANDROID__
static pthread_once_t api_once = PTHREAD_ONCE_INIT;
static bool api_ready;

static void initialize_api(void) { api_ready = load_api(); }

__attribute__((visibility("default")))
Reader *zauxoflix_seek_open(const char *source, const char *headers) {
  pthread_once(&api_once, initialize_api);
  if (!api_ready) return NULL;
  Reader *reader = calloc(1, sizeof(*reader));
  if (!reader) return NULL;
  if (open_reader(reader, source, headers)) return reader;
  close_reader(reader);
  free(reader);
  return NULL;
}

typedef struct {
  int64_t *times;
  uint8_t *images;
  int slot;
} FrameBatch;

static void store_frame(void *context, int64_t time, const uint8_t *pixels) {
  FrameBatch *batch = context;
  const size_t size = kWidth * kHeight * 3;
  batch->times[batch->slot] = time;
  if (pixels) memcpy(batch->images + batch->slot * size, pixels, size);
  ++batch->slot;
}

__attribute__((visibility("default")))
void zauxoflix_seek_read(Reader *reader, int64_t target, int64_t *times, uint8_t *images) {
  FrameBatch batch = { times, images, 0 };
  capture(reader, target, store_frame, &batch);
}

typedef void (*FrameUpdate)(int slot, int64_t time, const uint8_t *pixels);

typedef struct {
  FrameUpdate update;
  int slot;
} FrameUpdates;

static void send_frame(void *context, int64_t time, const uint8_t *pixels) {
  FrameUpdates *updates = context;
  if (pixels) updates->update(updates->slot, time, pixels);
  ++updates->slot;
}

__attribute__((visibility("default")))
void zauxoflix_seek_read_incremental(Reader *reader, int64_t target,
    FrameUpdate update) {
  FrameUpdates updates = { update, 0 };
  capture(reader, target, send_frame, &updates);
}

__attribute__((visibility("default")))
void zauxoflix_seek_close(Reader *reader) {
  close_reader(reader);
  free(reader);
}
#endif

#if !defined(__ANDROID__) || defined(SEEK_FRAMES_STANDALONE)
static void stream_frame(void *context, int64_t time, const uint8_t *pixels) {
  (void)context;
  if (fwrite(&time, sizeof(time), 1, stdout) == 1 && pixels) {
    fwrite(pixels, kWidth * kHeight * 3, 1, stdout);
  }
  fflush(stdout);
}

int ZauxoflixSeekFrames(void) {
  setpriority(PRIO_PROCESS, 0, 10);
  char source[16384];
  char position[32];
  if (!fgets(source, sizeof(source), stdin) || !strchr(source, '\n')) return 1;
  *strchr(source, '\n') = '\0';
  if (!load_api()) return 2;
  api.av_log_set_level(AV_LOG_QUIET);
  Reader reader = { 0 };
  const bool ready = open_reader(&reader, source, NULL);
  if (ready) {
    while (fgets(position, sizeof(position), stdin) && !ferror(stdout)) {
      const int64_t requested = strtoll(position, NULL, 10);
      const int64_t duration = reader.demuxer->duration / 1000;
      if (requested < 0 || (duration > 0 && requested > duration + 1000)) break;
      capture(&reader, requested, stream_frame, NULL);
    }
  }
  close_reader(&reader);
  return ready ? 0 : 3;
}
#endif

#ifdef SEEK_FRAMES_STANDALONE
int main(void) { return ZauxoflixSeekFrames(); }
#endif
