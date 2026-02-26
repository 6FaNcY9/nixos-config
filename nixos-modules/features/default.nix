# Feature Modules - Top-level Aggregator
#
# This module serves as the central import point for all feature categories.
# Features are organized into logical groups (desktop, development, hardware,
# security, services, storage, theme) and must be explicitly enabled via
# options in host configurations (features.<category>.<feature>.enable = true).
{
  imports = [
    # Desktop features
    ./desktop

    # Development features
    ./development

    # Hardware features
    ./hardware

    # Security features
    ./security

    # Service features
    ./services

    # Storage features
    ./storage

    # Theme features
    ./theme
  ];
}
