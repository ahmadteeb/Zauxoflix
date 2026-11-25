import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'media_artwork.dart';

/// A compact content card for channel directories and episode lists. Extra
/// actions remain independently operable alongside the row's primary action.
class CatalogRowCard extends StatefulWidget {
  const CatalogRowCard({
    super.key,
    required this.title,
    required this.onSelect,
    this.caption,
    this.description,
    this.image,
    required this.icon,
    this.logo = false,
    this.selected = false,
    this.autofocus = false,
    this.compact = false,
    this.previewDescription = false,
    this.progress,
    this.trailing,
    this.onFocus,
    this.blended = false,
  });
  final String title;
  final String? caption, description, image;
  final IconData icon;
  final bool logo, selected, autofocus, compact, previewDescription, blended;
  final double? progress;
  final VoidCallback onSelect;
  final Widget? trailing;
  final ValueChanged<bool>? onFocus;

  @override
  State<CatalogRowCard> createState() => _CatalogRowCardState();
}

class _CatalogRowCardState extends State<CatalogRowCard> {
  bool focused = false, hovered = false;
  @override
  Widget build(BuildContext context) {
    final active = focused || hovered;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 160);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: widget.blended ? const Color(0x7920202C) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          autofocus: widget.autofocus,
          onTap: widget.onSelect,
          onFocusChange: (v) {
            setState(() => focused = v);
            widget.onFocus?.call(v);
          },
          onHover: (v) => setState(() => hovered = v),
          child: AnimatedContainer(
            duration: duration,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 7 : 10,
              vertical: widget.compact ? 5 : 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: (active || widget.selected)
                  ? widget.blended
                        ? const Color(0x88372B40)
                        : AppColors.surfaceLight
                  : Colors.transparent,
              border: Border.all(
                width: 2,
                color: focused
                    ? AppColors.focusRing
                    : widget.selected && !widget.blended
                    ? AppColors.primary.withValues(alpha: .65)
                    : Colors.transparent,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 340;
                final width = widget.compact
                    ? 48.0
                    : narrow
                    ? 66.0
                    : c.maxWidth >= 600
                    ? 116.0
                    : 82.0;
                return Row(
                  children: [
                    MediaArtwork(
                      url: widget.image,
                      title: widget.title,
                      kind: widget.logo
                          ? ArtworkKind.live
                          : ArtworkKind.episode,
                      width: width,
                      height: width * (widget.logo ? .70 : .64),
                      cacheWidth: (width * 2).round(),
                      logo: widget.logo,
                      icon: widget.icon,
                      progress: widget.progress,
                    ),
                    SizedBox(width: narrow ? 8 : 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.caption?.isNotEmpty == true)
                            Flexible(
                              child: Text(
                                widget.caption!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFBDC0CC),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Flexible(
                            flex: 2,
                            child: Text(
                              widget.title,
                              maxLines: widget.compact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.compact ? 14 : 15,
                                height: 1.19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (widget.description?.isNotEmpty == true &&
                              (!widget.previewDescription ||
                                  active ||
                                  widget.selected))
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  widget.description!,
                                  maxLines: widget.compact || narrow ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFC1C1C9),
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.selected)
                      const Padding(
                        padding: EdgeInsetsDirectional.only(start: 5),
                        child: Icon(
                          Icons.equalizer_rounded,
                          color: AppColors.primary,
                          size: 18,
                          semanticLabel: 'Now playing',
                        ),
                      ),
                    if (widget.trailing != null) widget.trailing!,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
