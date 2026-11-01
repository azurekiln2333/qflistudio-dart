# Expansion B — authored Dart lessons 181–238
Status: standalone exercise gate pending a bounded host execution slot.
Date: October 23, 2026 (Asia/Shanghai). Source ownership is limited to the five new chapter files below. Production aggregators, asset catalogs, counts, old chapters, runtime, vendor and shared core were not edited by this author. These are drafts pending the root integration/device gates.
## Scope and content
58 unique lesson programs and 58 paired examples; each pair deliberately shares its own program. Each lesson now also has one **complete standalone exercise solution**, including imports, required declarations and `main`. All 58 explanations are Chinese and contain 170–219 characters; each entry has at least three concepts and two distinct pitfalls, plus an exercise prompt and hint. No lesson/exercise program uses stdin or a network call. File cleanup examples create and delete their own temporary directories.
| Chapter | IDs | Lessons | Paired entries | Standalone solutions |
| --- | --- | ---: | ---: | ---: |
| math-stats | 181–192 | 12 | 24 | 12 |
| oop-modeling | 193–204 | 12 | 24 | 12 |
| enum-states | 205–215 | 11 | 22 | 11 |
| errors-resilience | 216–226 | 11 | 22 | 11 |
| json-modeling | 227–238 | 12 | 24 | 12 |
| Total | 181–238 | 58 | 116 | 58 |
The programs implement distinct topics: number theory, matrix/statistical algorithms, value objects and interface behavior, finite-state workflows and permissions, bounded/classified retries and real resource cleanup, JSON model mapping/round trips/recursive flattening/deep merge/dirty-data reports. No output substitution or number-swapped lesson template was used.
## Actual execution evidence
The ignored harness `.dart_tool/expansion-b/verify.dart` imports the five authoritative chapter lists directly. For each entry it writes that exact authored source to a temporary program file, launches `Platform.resolvedExecutable` as the real host SDK, then calls `runPortableContent` from `tool/portable_content_runner.dart`. That helper calls the production `startPortableDart` implementation with the real offline policy and isolate supervisor. It uses the normal package configuration and no runtime fallback. SDK/portable stdout must match exactly after CRLF normalization; lesson/example stdout also must equal the authored output. Exercise stdout is first observed from real SDK execution, then compared with the portable output. Both exit status and stderr are checked.
Completed paired-program runs (all zero failures):

```text
dart --packages=.dart_tool/package_config.json .dart_tool/expansion-b/verify.dart
  # initial math-only harness: 12 unique / 24 paired entries
dart --packages=.dart_tool/package_config.json .dart_tool/expansion-b/verify.dart oop-modeling
  # 12 unique / 24 paired entries
dart --packages=.dart_tool/package_config.json .dart_tool/expansion-b/verify.dart enum-states errors-resilience
  # 22 unique / 44 paired entries
dart --packages=.dart_tool/package_config.json .dart_tool/expansion-b/verify.dart json-modeling
  # 12 unique / 24 paired entries
```
The successful machine reports remain under `.dart_tool/expansion-b/` as `results.json`, `results-oop-modeling.json`, `results-enum-states-errors-resilience.json`, and `results-json-modeling.json`. They contain expected stdout, actual SDK stdout/stderr/status and actual portable stdout/errors for every lesson/example. The expected output fields in the chapter files were recorded from actual SDK runs, then independently compared with product execution.
One genuine portable mismatch was repaired without reducing behavior: a contextually typed empty set literal `{}` was interpreted as a map inside a state transition table. Empty terminal sets are now explicitly written `<OrderState>{}` / `<ReviewState>{}`. The full enum+resilience rerun passed 44/44 entries.
A later all-three-kind run of the standalone answers passed IDs 181–198 (54 lesson/example/exercise entries), then SDK subprocesses for 199/exercise and 200/lesson failed with VM **Out of memory** (`-1073740791`). Their portable executions still returned the correct output. A following truncated process error stream caused UTF-8 decoding to fail, aborting that run. This infrastructure failure is not counted as a passing exercise gate. No further host process was started after the parent requested exclusive host-slot ownership. The harness now checkpoints after each entry, captures crash output as bytes, and stops immediately on an SDK OOM.
Standalone exercises are fully authored but their complete 58-program rerun is pending host-slot allocation.
Formatting was run on all five chapter files. `dart analyze` of the five files passed with zero issues before the final standalone-solution expansion; a final bounded analyzer rerun is pending unless recorded below.
## Current source hashes
SHA-256 covers the actual current chapter file bytes. The per-program hashes below cover the exact Dart string value (LF), including its final newline; the paired example uses the lesson program hash.
| Chapter file | SHA-256 |
| --- | --- |
| `curriculum/chapters/math_stats.dart` | `3e2f7927fc08726fcdd69ae9f54b6f6bfc4379d579e9d87dd0825f787937edcb` |
| `curriculum/chapters/oop_modeling.dart` | `57468525fb051b79fe8eb2c47594414f01e6f08f83e972c4750d58b02bf5ea63` |
| `curriculum/chapters/enum_states.dart` | `ea0881f1692574c462aee2d93a5445cf1b28ab1dd9e7e2855ee7b0cfba4ba90b` |
| `curriculum/chapters/errors_resilience.dart` | `96c0e8a44334a578de035907e754d069dc071e8df2ef0ada593f6c351e392689` |
| `curriculum/chapters/json_modeling.dart` | `dce78bc52adcf13af75a208f9fba1fe94e92b01f724039a5c321681cbba94a93` |

| Lesson | Lesson/example program SHA-256 | Standalone exercise SHA-256 |
| --- | --- | --- |
| 181 | `2dda89738830feb080809935593d7638a4ae13a13aa56ef51bfe9880f7c89c95` | `5aeb1c9c744774c79fa2d072641f95ed98b9282e191c7946b87ef39bc2a67145` |
| 182 | `042941edf1f5741222a589c6159392e4606febdac252f64f4065e290e5370426` | `9854864328641239d8597f9f00ff4c004a0cda7e2923b272af33c109bbdc0536` |
| 183 | `33cc7f42794c81094f8986e7c10352a96ce623886442104715f34acf72d9f35c` | `f0b86532c97c5a8fa7f4326710a8859a1cd8e51794de6c162eb1108fb9b9924c` |
| 184 | `c57c2a10efda9c5acea47fe3e5ee6cef2954321426458ee08a1e89717d57cf5f` | `a269d1019120b5c6092f2242991e587746599df11420c5cc8bf5f46afbf71ac0` |
| 185 | `cdf4c67dc770b7784b335ed8b0b0e25e37610b9a06350a6848199ce4e5f424ee` | `4be6d2683960a3044e16fc09e1f390fff388435c55991e1981d7ccabf9498fd4` |
| 186 | `e0414b34ea774371306d88b37bf17ce2b11bc7de4ff9f1a3e03ed77728083db3` | `7bcfdd917ed159c46aae61ae6ad17c3361571479172ef148fb1c036f5b21535f` |
| 187 | `1b1ebaa6b5c2298cd030e74cfdc6e7c601c018368504da4feff0105bfadbd50c` | `bc3e6a06c204fe19c5102a4bf89e70e7f3146ca8b50d72f03df99fdbc57aec8c` |
| 188 | `bcc229df6bfc8e2ffc29eefc20916cf8ef7878830b051c124d594a0ab445dc9d` | `d332aef89331e703a7fe690692b93acb37c9ab08cddc542a562fc7f3bc18e78c` |
| 189 | `04f09c19ea02a7c4e7c46def234cd47f442971bfe25738f4ccc2a774f744c168` | `97b48461b1082aaa3241a89cfb774670ab6422814a9ff250560d87f6d2f9dcbb` |
| 190 | `b3adedad4099ac4783619d076eba900a57988b0fc083e959dbf3a66401609e3b` | `aa6ad0968fa7f132a57ec79934a58a65a511a069bee0696ab977620e2ccefa72` |
| 191 | `ef597326d8dea575ac15e12533ff155e896ce96e7c99d348170ba52c95b5cd5f` | `f20f30a136d1664cb421fd13f7036f21566197d31e5034df0330819b1189e65d` |
| 192 | `5afec0fc81dee9447e5c9b1435c21f395ecba55e6337b98a5b79e9cc158d46dc` | `803135a82bc1790b4e5c66174b43443de0dffc8f67670498534ee16480fc7529` |
| 193 | `d28414cce3d9633c77f9fe83f164ab8c1fd8e4d231f6fe236c3bbe36e6d5c45f` | `4f49060ec160444068e2fb2eaabe89d4c400a02ede3cccfb1e2198b43401ed50` |
| 194 | `9d74c0e7127e7b98c50b394da40259706c54be53c7d9623b9c1cb6180fd4cb25` | `eba7fcccd4323f894c82270b034a26108a2ec52f4750c51273c99c900f94a0bb` |
| 195 | `cd7b3ec4870a292751c7376b8d821c0552cf43f03fb0b5f3286aee97643e9eae` | `2c874610984a695e81aa2351af755825d7280b0802caab0d1cfa8bc25b0afae0` |
| 196 | `35a41f79e0b0387fab2daf2de36f6071aa51ec525d4d514d80d849a6428a8d4a` | `f97dfd93360d35325fc1a7f0828f25237425a59b75abf30553ec07750ee4be40` |
| 197 | `834cc1dd5d87e42fa5076e8a7dcd89ff34e186e0a3ef9ee3a86160074d950cba` | `0329bbb9c51e492e1023bece8d085a7c92353ee9596ac75f24eeeb7b74e21ca4` |
| 198 | `fd6f4fad1e852781cb9746fb3debdc01cce4d67e05de1d1697ad5a84551af71a` | `2ea60d6c810f16eec84065a5cf3280d3df7690f3764307579b2a469c1828dd5e` |
| 199 | `b70bafca78304cbb4224fe42bb8e4fa3cfbce838c20ddbe69ebc3118d98139d8` | `354b28f8dc5970eec4d1c82882b8c672be7a306d1c53e4ed9f05c268b1965327` |
| 200 | `4e9dddf61d31c6d06cd98f2b2a7825c8dee818109fdbb96c7a7bff0aef897b37` | `72949e8f470559103bef9f77129f3dbb9690a20795c82a07f80d3590719fb855` |
| 201 | `398231c413dab437eed4c0cbfbcc11a3b741ed35224ff86f35cef05dd06b5f20` | `6f1e99777b2a731291ead38b33e58c90d7aa683c3cb43bb4a9650db9b3a7b1e8` |
| 202 | `f5a50e5eebe32ca12403821361444702248d093afd74865add832e8695dff4eb` | `fb499890f8f5508f3d86c8b3660d1e8b09619dc4f6c4ff54d065ea643383de9b` |
| 203 | `d2126f0b9989ceae45a9066ad23fb1a79d262a9eb6bb12269f50456074c9814b` | `3730274933bddec2549df3011821d8e95ebf305b4963a703a7e32377538e709d` |
| 204 | `ffd9cf58c28cceaa19c8c00dabc41ef332c9922cbb84de4803c651fbd0070ab0` | `43d5ff65610eb70f611a09531332697a6e0c9862502d2d30b3b00e18c9059615` |
| 205 | `2173245769a827fe5496f96e24f0f420b41336974e1f32ce9f758f4b74d2af7a` | `1a6a5ce320185495e476f2b7744a6531667f518842ed6b1dd1e01c7978690099` |
| 206 | `e6ef0bae8739ae9a75c711095acf75bba534b9e581bf9d3c7d7cb7d168312a65` | `d3f789234c2b518e12e0c192b9b654da3dc5e989234e783960dd566c7c3d1f20` |
| 207 | `a3195573779471898177712c72f49029ae425bb27bb7d7c26d27d0834a6755b5` | `296b4cacb5d34ec21d8967d42c7050c823fd3e7bec4bcfa6c19a268bf2e8a226` |
| 208 | `fbb4ff12cf5de1812df10cccbc8fe30c05a4baecb9c5f7fdf0ffe81e3ff04843` | `44b90e779c9eb692854cb7fb5afe3e86111b09dc354d3fe4dea43e1c5cc3bdfd` |
| 209 | `446577332bf11a4d136ff90a49d539139a6a51cd29b4c226d5ec12b427b399b3` | `63bd3bd2bf276aa55aa7bd32849da3ddde046f4ed6fb7f6474c49e1ae15af9f9` |
| 210 | `99eec8b60eff771ed3ea4b38bc220b93e92cf3776aee9c28bb86063d2ff1dfbe` | `96cba6c856f45c696de63749dcc03455d2020c39ff1be2ec0151858e52a2fe43` |
| 211 | `9cf0be5ebbe001adb4a920b9681ee3d74e6a9d8406480faa1107ac12c2d0d9e7` | `41096796927457252ff8c244c4f468f75c4054cb11da267800b273f7084f0565` |
| 212 | `fd1f283f65939d1e36bf00fc126e561a481ed7742e82c3bd9606ca3ee9822b13` | `29254e9718abf020d9d1f2d7535f07ab4ebbeda8b8e2509ad89055c7b6bee518` |
| 213 | `2c26deacc4e50874d9058f93e68a075e888e164915361d43a30dc3f08e280e6a` | `aaecb69784512a11f91ac8691fdb5094eeb6f8b6b2661cb33080cb9de0114ad8` |
| 214 | `12adcc2a22e8dc316749d8440c48c23ad7a1bd19b003e288fc425d334370dae1` | `04d8209a18f67bcc00a4a83ecd27c9c8a522bbad2291b35e71cde01bdfd76d45` |
| 215 | `ad57ef8ae75b6559d375bc33c9502b150725f6948692c38ad4bcd274e13d019b` | `98151079005f83648571e9ebc42407c25418490ed6a885a8016666f7cf096cb6` |
| 216 | `c1e33a10e27a61f661d31e9808de93db40caca9d1306bf828f3a91c79da41c83` | `dec4b7d87d71eb4adad37bc436229ec07d5d86aa6c4b25a5edb9c3d8e628e06b` |
| 217 | `616347e1175b3b295baa1d5ee065fda36f61ee91de61b5150526a0cf1983c8d6` | `d121575d166af09ca4f6adff89fddc8c306d027e47c9944880c399bd69280ea2` |
| 218 | `84d232514b6b46efb6f4a4125fe841ab5a6b42676374f95d7a34326dd864da4d` | `a707d4a47ec8ae0fa2f8d713069e104ebd79923438a99326b3de9004f9f50d57` |
| 219 | `4d36bd072caec18869d8a188f1415ac78bcce0f15ec3de5da15240ab2d180556` | `1edb6fd780761a9c294ce9b18cb4a24facafb249f3ef370302f8196b2e291055` |
| 220 | `720b08241fb570cc2cce663d4bd6b4d0985d789bac5d4ea7acf47ba563080c75` | `93d933d8bb6d07c960b8ba07e0f73bac47b426f58cf59db3eff472be514cc0f9` |
| 221 | `4f8705e75d4fc15c0fcfcd12310db9d45c0d68a45eb16302a57712e0d9ddf41e` | `4178163a3df6699a6d27163b6e948004915c2c68386505d5c26eb22beceda474` |
| 222 | `1f77ed34f322909ea0d94b0b462ea6efdb36f0f7dc715cb0b85a95f848c9b15f` | `36ed5007a54eeae7cd4329be5985c0910b41d7377456d2650071abf7e6f46ca1` |
| 223 | `431ddea831127507133423e871aa5fa64526ab08b1d7cb483dbc884504b2d487` | `563ff32bfb91132b23ea85939b28f343bf3855bfffff493727249fbc69fc5afd` |
| 224 | `3ab7a72173ecab2851a5dd926d8935a9c7040aedb28b4d723f0ceba06477d4ff` | `0f65b952d39a10be4fd11a3f7b210f83708aab21699c3c43a316e6739b69f841` |
| 225 | `7665853c7c18fe87453dc614696128417a8f4117f2b920602a0088822a57323c` | `110e2755ff80dcfb65080a4f4e1b86eb8bf22fdc2d8060b550292f6f2594f376` |
| 226 | `253c555bc41a766b2c7ac3b568085d43e4e3941b1818caf13b6512950096a9c0` | `b4f80108c9df7aaedb4010d45c705535b791bd0edd7726a6d7b2dc8667f20814` |
| 227 | `04b1ef7ccd95210070d563309fba400b0432b00a984f5ea6b7be5a4f1ddad388` | `962fc65bd6f091b56bf5bd08f02929e1032ccf80b354b9c139549c684f7938ac` |
| 228 | `b3ad40ad49daa9408230d81d6b6ea9e7400d9b836a5c569b0f95ecce928d59cb` | `d2557e32adf34b4893310a64998b653b51154c27074cba45ff2e117d7a2eed89` |
| 229 | `898c3a844ccc7cc7714d6e428f6ab11e79ed3674a9490a1d78ba4294e9fe2e4e` | `8200ea4a37849579ad8e891a80eb2c028a972d2c716d41b0031ee8d227f9dcde` |
| 230 | `546781df05ba87678a874eac4d4041f5e5bd175ee9262d447e33bab9dd296640` | `b7c16cfdeaf1c1fb1e82471eac12eeaddcc243b41a7c5600ba00182c58ccdfe3` |
| 231 | `915cb327be437607cea49482fa65b122cdb871f78f04a40c52d1c831f2f3b510` | `ccd36dd1fa00417fca9169e8c12c86242aa94462541b8b7f6d77297439f48185` |
| 232 | `735539379f60a385ef9463ee1e397b444529260d1a1286c3002c8fff20e38599` | `06041fef2c14e7324d62c8c5c3622248ba8f5aa2889e2de50e6e699f149b7ae9` |
| 233 | `b64c552b1d1a87e18b5b1367d71062ca7b9a79900e4b7a5784993d57ecc0b913` | `2f49c38fdb06148fd5a29544b51463f73418fdab290bfd85509be3bba9a7b3c1` |
| 234 | `023e2e1822f0e24b3f8510a6d22c1f0d5ad00f43e12a721434a22d10cc2161bf` | `9dbc02bb6c763b0663a1963e4235fe8c5d5a293d38d801289b98ea9b91959aa2` |
| 235 | `a9bc7b4584c9bf57f924e4cedf73dc4777e0af0b18501e62c2eee33e99c202d2` | `071d085026ffbb43c4b1ef7d0079d7bd6aa8a80bd2a5d07a4032714e7b25fa5b` |
| 236 | `22f309c3bcec2a29ef184535473ed13d10278553be2298132ef715f8020941dd` | `7331b4dd044c9e535bee832c6e019ba4ed97961d226c995236269f1f69d86d90` |
| 237 | `a9838540b3ff89ba2fe0039dc78c1a23bdefbbe046d45d564c55fb5d16c10af6` | `bd73cf772b3c585bd5d5f84f6825a887b7040ab276b3638e9de98b2be84d407a` |
| 238 | `b32aa2f410a2247ea9b901ae287c66ebf817577d3266a201513e711425599227` | `ef227695703a29d8e4c8a6dd9fd9b35f96178f6238dd1135b5dfd25b4e4f35e8` |

## Remaining integration boundaries
The five files are not added to the production curriculum/asset aggregate by this author. Host SDK success, host product-portable success, OHOS build success and actual OHOS-device execution are separate evidence. **No OHOS device execution is claimed.** Root integration owns the original OHOS gate, combined uniqueness/count checks, production generation, target build/device checks and release decisions.
