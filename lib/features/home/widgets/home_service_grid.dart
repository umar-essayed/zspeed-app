import 'dart:ui';
import 'package:flutter/material.dart';

class ServiceCategory {
  final String name;
  final String title;
  final String tag;
  final String image;
  final IconData icon;
  final Color color;
  final bool isActive;

  ServiceCategory({
    required this.name,
    this.title = '',
    this.tag = '',
    this.image = '',
    required this.icon,
    required this.color,
    this.isActive = true,
  });
}

class HomeServiceGrid extends StatelessWidget {
  final List<ServiceCategory> services;
  final Function(ServiceCategory) onServiceTap;

  const HomeServiceGrid({
    super.key,
    required this.services,
    required this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();

    // Divide services: first 2 are large cards, rest are small cards
    final largeServices = services.take(2).toList();
    final smallServices = services.skip(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row 1: Large Cards (Food & Groceries) ──
        Row(
          children: largeServices.map((service) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _LargeServiceCard(
                  service: service,
                  onTap: () => onServiceTap(service),
                ),
              ),
            );
          }).toList(),
        ),
        if (smallServices.isNotEmpty) ...[
          const SizedBox(height: 16),
          // ── Row 2: Small Cards (Transport, Pharmacy, Bookstores, Furniture) ──
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: smallServices.length,
              itemBuilder: (context, index) {
                final service = smallServices[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 6 : 0,
                    right: 12,
                  ),
                  child: _SmallServiceCard(
                    service: service,
                    onTap: () => onServiceTap(service),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _LargeServiceCard extends StatelessWidget {
  final ServiceCategory service;
  final VoidCallback onTap;

  const _LargeServiceCard({
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: service.isActive ? onTap : null,
      child: AspectRatio(
        aspectRatio: 1.05, // Square-ish proportion
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: service.image.isNotEmpty
                      ? Image.asset(
                          service.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: service.color.withValues(alpha: 0.2),
                            child: Icon(service.icon,
                                size: 40, color: service.color),
                          ),
                        )
                      : Container(
                          color: service.color.withValues(alpha: 0.2),
                          child: Icon(service.icon,
                              size: 40, color: service.color),
                        ),
                ),
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // Card Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Tag & Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tag
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 1.8, sigmaY: 1.8),
                                child: Text(
                                  service.tag,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Icon (Decorative)
                          Icon(
                            service.icon,
                            color:
                                Colors.amber.shade200.withValues(alpha: 0.85),
                            size: 22,
                          ),
                        ],
                      ),
                      // Bottom Row: Elegant Title
                      Text(
                        service.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // SOON overlay if inactive
                if (!service.isActive)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'SOON',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallServiceCard extends StatelessWidget {
  final ServiceCategory service;
  final VoidCallback onTap;

  const _SmallServiceCard({
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: service.isActive ? onTap : null,
      child: Container(
        width: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: service.image.isNotEmpty
                    ? Image.asset(
                        service.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: service.color.withValues(alpha: 0.2),
                          child: Icon(service.icon,
                              size: 30, color: service.color),
                        ),
                      )
                    : Container(
                        color: service.color.withValues(alpha: 0.2),
                        child:
                            Icon(service.icon, size: 30, color: service.color),
                      ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Card Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Tag
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              service.tag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Bottom: Title
                    Text(
                      service.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // SOON overlay if inactive
              if (!service.isActive)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SOON',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 8,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
