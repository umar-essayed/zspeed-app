enum UserRole {
  customer,
  driver,
  vendorOwner,
  admin,
  superAdmin,
  guest,
}

bool canInitiateCardPayment(UserRole role) => role == UserRole.customer;