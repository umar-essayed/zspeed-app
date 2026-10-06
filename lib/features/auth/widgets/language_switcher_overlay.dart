import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/localization/locale_cubit.dart';

class LanguageSwitcherOverlay extends StatelessWidget {
  const LanguageSwitcherOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    
    return Positioned(
      top: topPadding + 16,
      right: 20,
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, currentLocale) {
          final isArabic = currentLocale.languageCode == 'ar';
          
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 82,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      context.read<LocaleCubit>().toggleLanguage();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.public,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            isArabic ? 'EN' : 'AR',
                            key: ValueKey<bool>(isArabic),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.8,
                              fontFamily: isArabic ? null : 'Cairo',
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

