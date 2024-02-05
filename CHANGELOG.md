## [Unreleased]

## [0.4.0] - 2024-02-04

### Added

- Add `:value` input property to use a registered `BCDD::Value` to handle the input.
  ```ruby
  attribute :name, value: :name
  ```

- Add `:respond_to` input property to check if the value responds to a given method.
  ```ruby
  attribute :name, respond_to: :strip
  ```

### Changed

- Use `:type` property to check if the normalize should be applied.
  ```ruby
  attribute :name, type: String, normalize: -> { _1.strip }
  ```

## [0.3.1] - 2024-02-03

### Fixed

- Make the input `normalize:` work with Ruby `2.7`.

## [0.3.0] - 2024-02-03

### Added

- Allow the usage of `proc(&)` with the input `normalize:` property.
  ```ruby
  attribute :name, type: String, normalize: proc(&:to_s) >> proc(&:strip)
  ```

### Changed

- **BREAKING**: Remove `validate:` input property and allow the composition of `contract:` + `type:` properties.
  ```ruby
  # Before
  attribute :name, type: String, validate: :is_present

  # After
  attribute :name, type: String, contract: is_present
  ```

## [0.2.0] - 2024-02-01

### Changed

- **BREAKING**: Update gem's dependencies.
  - bcdd-contract >= 0.1.0
  - bcdd-result >= 0.3.0

## [0.1.0] - 2024-02-01

### Added

- Add `BCDD::Process` - Initial/POC release.
