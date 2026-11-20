Infinity Loop
Copyright (C) 2026 S. M. Shahin Reza Sifat / Motion Work

Infinity Loop is an independently maintained, modified distribution of Zangetsu by
Krishna Vishwakarma. Original source: https://github.com/Spyou/Zangetsu
Original work copyright (C) 2026 Krishna Vishwakarma.

Modified 2026-11-21 to use its own branding, Android application identity,
release signature, GitHub release channel, and service configuration.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3.0 (GPL-3.0) as published
by the Free Software Foundation. See the LICENSE file for the full text.

The vast majority of this project is original work. The notices below cover the
third-party code it incorporates, and the licenses that apply to those parts.

────────────────────────────────────────────────────────────────────────────
Third-party components
────────────────────────────────────────────────────────────────────────────

CloudStream (recloudstream)
  https://github.com/recloudstream/cloudstream
  License: GPL-3.0
  Zangetsu bundles the CloudStream `library` artifact and includes app-internal
  compatibility classes under the `com.lagradost.cloudstream3` namespace so that
  CloudStream `.cs3` extensions load and run against it. Because CloudStream is
  licensed under GPL-3.0 (copyleft), Zangetsu as a combined work is likewise
  licensed under GPL-3.0.

Aniyomi / Tachiyomi
  https://github.com/aniyomiorg/aniyomi
  https://github.com/tachiyomiorg/tachiyomi
  License: Apache-2.0
  Portions of the Android extension-loading code (files under
  android/app/src/main/kotlin/com/motionwork/infinityloop/aniyomi/) are derived from
  Aniyomi/Tachiyomi and retain their original Apache-2.0 headers. The full
  Apache License 2.0 text is included as LICENSE-Apache-2.0.txt.

Other dependencies (Flutter/Dart packages and Android libraries) are used under
their respective open-source licenses; refer to each package for details.

────────────────────────────────────────────────────────────────────────────
Keeping this file current
────────────────────────────────────────────────────────────────────────────

Any pull request that adds a new third-party dependency, incorporates code
derived from another project, or bundles another project's assets must update
this file in the same PR — see CONTRIBUTING.md. This file is treated as the
authoritative record of what's bundled and under what terms; if it's out of
date, that's considered a bug, not a formality.

────────────────────────────────────────────────────────────────────────────
Reporting a concern
────────────────────────────────────────────────────────────────────────────

If you believe this project incorporates third-party code, assets, or content
without proper attribution or in violation of its license, please open an
issue or contact Spyou directly (https://github.com/Spyou) so it can be
corrected or removed.
