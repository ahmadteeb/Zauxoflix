// Copyright (c) 2026 LG Electronics, Inc. All rights reserved.
// Copyright 2021 Sony Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter_webos.h>
#include <flutter_window.h>

#include <cstring>

#include "flutter/generated_plugin_registrant.h"

extern "C" int ZauxoflixSeekFrames();

class App : public FlutterWindow {
 public:
  bool OnCreate() override {
    if (!FlutterWindow::OnCreate()) return false;
    auto* registry = GetRegistrar();
    RegisterPlugins(registry);

    // Ask the compositor to deliver short Back presses to this app's window.
    // Once received, Flutter can dismiss the current overlay or pop its route.
    auto registrar = registry->GetRegistrarForPlugin("ZauxoflixRemote");
    if (auto view = FlutterDesktopPluginRegistrarGetView(registrar)) {
      FlutterDesktopViewSetWindowProperty(
          view, "_WEBOS_ACCESS_POLICY_KEYS_BACK", "true");
    }
    return true;
  }
};

int main(int argc, char** argv) {
  if (argc == 2 && std::strcmp(argv[1], "--seek-frames") == 0) {
    return ZauxoflixSeekFrames();
  }
  App app;
  return app.Run(argc, argv);
}
