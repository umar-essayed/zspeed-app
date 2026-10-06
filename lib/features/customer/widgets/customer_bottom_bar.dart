import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Bottom bar for the customer app with 4 tabs:
/// Home, Browse, Cart (with badge), Track Order.
class CustomerBottomBar extends StatelessWidget {
  final String activeView;
  final int cartItemCount;
  final VoidCallback onHome;
  final VoidCallback onBrowse;
  final VoidCallback onCart;
  final VoidCallback onTrack;
  final bool isScrolling;
  final bool showOnlyHome;
  final bool hideBottomBar;

  const CustomerBottomBar({
    super.key,
    required this.activeView,
    required this.cartItemCount,
    required this.onHome,
    required this.onBrowse,
    required this.onCart,
    required this.onTrack,
    this.isScrolling = false,
    this.showOnlyHome = false,
    this.hideBottomBar = false,
  });

  int get _activeIndex {
    switch (activeView) {
      case 'home':
        return 0;
      case 'browse':
        return 1;
      case 'cart':
        return 2;
      case 'tracking':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hideBottomBar) {
      return const SizedBox.shrink();
    }

    final double targetWidth = MediaQuery.of(context).size.width;
    final double targetHeight = (isScrolling ? 50.0 : 64.0) + 20.0;

    return SizedBox(
      height: targetHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: showOnlyHome ? 100.0 : targetWidth,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: EdgeInsets.fromLTRB(
                showOnlyHome ? 0 : (isScrolling ? 48 : 16), 
                0, 
                showOnlyHome ? 0 : (isScrolling ? 48 : 16), 
                12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    height: isScrolling ? 50 : 64,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        final buttonWidth = totalWidth / (showOnlyHome ? 1 : 4);
                        final activeIndex = showOnlyHome ? 0 : _activeIndex;

                        const horizontalPadding = 0.0;
                        const verticalPadding = 0.0;
                        final calculatedHeight =
                            (isScrolling ? 50.0 : 64.0) - (verticalPadding * 2) - 2;

                        return Stack(
                          children: [
                            // Sliding Active Indicator Behind Buttons
                            AnimatedPositionedDirectional(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              start: activeIndex * buttonWidth + horizontalPadding,
                              top: verticalPadding,
                              width: buttonWidth - (horizontalPadding * 2),
                              height: calculatedHeight > 0 ? calculatedHeight : 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(35),
                                ),
                              ),
                            ),

                            // The Buttons Row
                            Positioned.fill(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: showOnlyHome
                                    ? [
                                        Expanded(
                                          child: _buildNavButton(
                                            context,
                                            AppLocalizations.of(context)!.homeTab,
                                            Icons.home_outlined,
                                            true,
                                            onHome,
                                          ),
                                        ),
                                      ]
                                    : [
                                        Expanded(
                                          child: _buildNavButton(
                                            context,
                                            AppLocalizations.of(context)!.homeTab,
                                            Icons.home_outlined,
                                            activeView == "home",
                                            onHome,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildNavButton(
                                            context,
                                            AppLocalizations.of(context)!.browseTab,
                                            Icons.explore_outlined,
                                            activeView == "browse",
                                            onBrowse,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildCartButton(
                                            context,
                                            activeView == "cart",
                                            onCart,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildNavButton(
                                            context,
                                            AppLocalizations.of(context)!.trackOrderTab,
                                            Icons.location_on_outlined,
                                            activeView == "tracking",
                                            onTrack,
                                          ),
                                        ),
                                      ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String title, IconData icon,
      bool isActive, VoidCallback onTap) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Colors.white.withValues(alpha: 0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(35),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          vertical: isScrolling ? 4 : 6,
          horizontal: isScrolling ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 20,
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: isScrolling
                    ? const SizedBox.shrink()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 3),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isActive ? activeColor : inactiveColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cart button with item count badge.
  Widget _buildCartButton(
      BuildContext context, bool isActive, VoidCallback onTap) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Colors.white.withValues(alpha: 0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(35),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          vertical: isScrolling ? 4 : 6,
          horizontal: isScrolling ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: isActive ? activeColor : inactiveColor,
                  size: 20,
                ),
                if (cartItemCount > 0)
                  PositionedDirectional(
                    end: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '$cartItemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: isScrolling
                    ? const SizedBox.shrink()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 3),
                          Text(
                            AppLocalizations.of(context)!.cartTab,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isActive ? activeColor : inactiveColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
