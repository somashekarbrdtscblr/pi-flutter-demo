/// Build-time config, compiled in from `.env.<target>` by `scripts/build.sh`
/// (`--dart-define-from-file`). Values are fixed per build, like React's
/// `process.env.REACT_APP_*`. Add a key to `.env.web.example` and
/// `.env.pi.example` whenever you add one here.
///
/// Must stay `const`: `String.fromEnvironment` only works in a const context.
abstract final class Env {
  static const baseApi = String.fromEnvironment('CHOTAPOS_BASE_API');
}
