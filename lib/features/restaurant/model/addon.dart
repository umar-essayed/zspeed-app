/// Addon model for individual addon options in a group.
///
/// This is a convenience alias — the canonical model is [AddonOption]
/// from `addon_group.dart`. This file re-exports it as `Addon` for
/// backward compatibility with widgets that reference the `Addon` type.
library;

export 'package:z_speed/features/restaurant/model/addon_group.dart'
    show AddonOption;

import 'package:z_speed/features/restaurant/model/addon_group.dart';

/// Type alias for backward compatibility.
typedef Addon = AddonOption;

/// Extension to provide `price` getter on AddonOption for backward compat.
extension AddonOptionPriceAlias on AddonOption {
  double get price => extraPrice;
}
