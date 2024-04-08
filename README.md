# SW_BattleMatchmaker
## 概要
BattleMatchmakerはStormworks WeaponDLCを用いてのTDMを支援するアドオンです。

joinコマンドでプレイヤーがチームに所属すると、状態が画面左に表示されます。
その後readyコマンド全員が準備状態になるとカウントダウンが始まり、試合が開始されます。
時間切れか生存者のいるチームが一つになると試合が終了します。

プレイヤーが死ぬ、プレイヤーに紐付けられた車両が破壊される、コマンドで自殺する、のいずれかでプレイヤーは死亡状態になります。
車両については後述の項目を参照してください。

## 試合の簡単な流れ
#### 1. チームに参加する
`?mm join (チーム名)` でチームに参加できます。
チームに参加すると画面左にプレイヤーリストが表示されます。

また `?mm supply` で出したサプライについているJoin◯◯ボタンを押してチームに所属することもできます。

リスト表示が見えない場合は `?mm reset_ui` を試してみてください。

#### 2. 車両を出して登録する
チームに参加した状態で車両に乗ると、その車両が自分の乗機として登録されます。
車両が登録されると左のリストにHPがが表示されます。

#### 3. 準備
車両を開始地点に移動させます。
車両が登録されている状態で `?mm order` することで、目の前に車両をワープさせることができます。

**準備ができたら `?mm ready` でReady状態にします。**

#### 4. 試合開始
参加者が全員Ready状態になると試合が始まります。

#### 5. 試合終了
管理者が `?mm reset` するか、全員いちどチームを抜けるかしてリセット

### 管理者向けTips
admin権限のあるユーザーはより細かいコマンドオプションが使えます。

- `?mm flag [名前]` で今いる場所に旗を立てることができます。旗はマップから確認できるので、スタート地点を指定するのに使えます
- `?mm join` などのコマンドは、末尾にpeer_idを指定することで他人を操作できます
- `?mm shuffle [チーム数(2-4)]` でjoin済プレイヤーを適当にチーム分けできます
- HP固定にしたい場合は `?mm set vehicle_class false` でクラス制を無効にします

## コマンド
### プレイヤー用コマンド
プレイヤー用コマンドの実行にはAuthが必要です。

- `?mm`<br>
  コマンド一覧と現在設定を表示
- `?mm reset_ui`<br>
  UI IDを更新する<br>
  joinしても左の状態表示Popupが出ないときに実行してください
- `?mm join (チーム名)`<br>
  チームを作成・参加<br>
  チーム名を省略した場合はStandbyチームに所属する
- `?mm leave`<br>
  チームから離脱
- `?mm ready`<br>
  自分を準備状態に設定
- `?mm wait`<br>
  自分を待機状態に設定
- `?mm die`<br>
  自分を死亡状態に設定（自殺）
- `?mm order`<br>
  車両をプレイヤーの位置にテレポートさせる
- `?mm start`<br>
  試合開始前カウントダウンを再開
- `?mm stop`<br>
  試合開始前カウントダウンを中断
- `?mm supply`<br>
  準備用の装備品類を設置
- `?mm delete_supply`<br>
  準備用の装備品類を削除

管理者はjoin/leave/ready/waitコマンドの末尾にpeer_idをつけることで他人をチームに入れたり抜いたりできます。

**現バージョンのStormworksでは、車両テレポートを行うとクライアント側でのみロープが消失します。**
もし困る場合はあらかじめEquipment Inventoryに格納しておくなどすることで回避できます。


### 管理者用コマンド
管理者用コマンドの実行にはAdminが必要です。

- `?mm ready_all`<br>
  join済のユーザーを全員readyする
- `?mm pause`<br>
  制限時間のタイマーを一時停止
- `?mm resume`<br>
  制限時間のタイマーを再開
- `?mm add_time [追加する時間(分)]`<br>
  制限時間を追加
- `?mm shuffle [チーム数(2-4)]`<br>
  ランダムにチーム分け
- `?mm reset`<br>
  状態をすべてリセット
- `?mm clear_supply`<br>
  全ての準備用の装備品類を削除
- `?mm flag [名前]`<br>
  旗を設置
- `?mm delete_flag [名前]`<br>
  旗を削除
- `?mm clear_flag`<br>
  すべての旗を削除
- `?mm set [設定名] [設定値]`<br>
  ゲーム設定を変更する<br>
  `?mm set` のみで設定名の一覧を表示する


## 車両
チームに所属しているプレイヤーが車両を出すか搭乗すると、その車両は撃破判定管理の対象になります。
車両がダメージを受けてHPがゼロになると、その車両は撃破判定になります。
プレイヤーが最後に搭乗した車両が撃破されると、プレイヤーは死亡判定になります。

`gc_vehicle` 設定が有効なとき、撃破された車両は10秒でデスポーンします。

## 弾薬補給
以下のいずれかの名前を付けたボタンを押すことで、プレイヤーの所持品にその弾薬をセットします。

ボタンを車両や拠点に設置することで、弾薬装填を楽しみつつ総残弾を気にせず戦えます。
(HP管理下の車両については、`supply_ammo` 設定の回数だけ弾薬を取得することができます。)

### 補給可能弾薬とボタン名の対応表
| Weapon Type        |     | Kinetic | High Explosive | Fragmentation | Armor Piercing | Incendiary |
| ------------------ | --- | ------- | -------------- | ------------- | -------------- | ---------- |
| Machine Gun        |     | MG_K    |                |               | MG_AP          | MG_I       |
| Light Auto Cannon  |     | LA_K    | LA_HE          | LA_F          | LA_AP          | LA_I       |
| Rotary Auto Cannon |     | RA_K    | RA_HE          | RA_F          | RA_AP          | RA_I       |
| Heavy Auto Cannon  |     | HA_K    | HA_HE          | HA_F          | HA_AP          | HA_I       |
| Battle Cannon      |     | BS_K    | BS_HE          | BS_F          | BS_AP          | BS_I       |
| Artillery Cannon   |     |         | AS_HE          | AS_F          | AS_AP          |            |

### MG弾薬の自動リロード
MGのマガジンパーツの名前を `magazine_1` `magazine_2` ...と設定することで自動リロードの対象になります。
数字は必ず1から始まる連番の数字である必要があり、10まで対応しています。
**Stormworksの仕様上、スポーン時の弾薬設定がUnloadedの場合は弾が補充されない点に注意してください。**

setコマンドで指定可能なインターバル間隔で残弾数チェックが行われ、残弾のないマガジンは**次のチェックのタイミング**で弾薬が補充されます。
また1回のチェックで補充されるマガジンは一つだけです。

補充可能回数はボタンによる弾薬補給可能回数と共有されます。

## 装備品類の呼び出し
`?mm supply` で準備用の装備品類を呼び出せます。
一人一つまで呼び出す事が可能で、試合開始と同時に削除されます。


## 旗の設置
管理者は `?mm flag (名前)` で旗を設置できます。
旗はマップ画面から視認可能です。集合場所の設定などに使用してください。


## 変更可能な設定
管理者は `?mm set` コマンドでゲームの設定を変更することができます。

- `?mm set vehicle_hp [HP]`<br>
  車両の初期HPを設定
- `?mm set vehicle_class [true|false]`<br>
  クラス制の有効無効を設定
- `?mm set max_damage [ダメージ量]`<br>
  1tickに受けられる最大ダメージ量
- `?mm set ammo_supply [true|false]`<br>
  弾薬補給を有効にするか設定
- `?mm set ammo_mg/ammo_la/ammo_ra/ammo_ha/ammo_bs/ammo_as [弾薬数]`<br>
  各砲タイプ毎の弾薬補給可能回数を設定<br>
  `-1` を指定すると無限
- `?mm set order_enabled [true|false]`<br>
  車両テレポートの可否を設定
- `?mm set cd_sec [カウントダウン時間(秒)]`<br>
  カウントダウン時間を設定
- `?mm set game_time [ゲーム制限時間(分)]`<br>
  ゲーム制限時間を設定
- `?mm set remind_time [残り時間のリマインド間隔(分)]`<br>
  残り時間のリマインド間隔を設定
- `?mm set tps_enabled [true|false]`<br>
  試合中に三人称視点を許可するかを設定
- `?mm set ext_volume [容量(%)]`<br>
  消化器の初期容量設定
- `?mm set torch_volume [容量(%)]`<br>
  修理トーチの初期容量設定
- `?mm set welder_volume [容量(%)]`<br>
  水中トーチの初期容量設定
- `?mm set gc_vehicle [true|false]`<br>
  撃破車両の自動削除設定
- `?mm set mg_auto_reload [true|false]`<br>
  マシンガン弾薬の自動リロード有効化
- `?mm set mg_reload_time [チェック間隔(秒)]`<br>
  マシンガン弾薬のチェック間隔設定
- `?mm set player_damage[true|false]`<br>
  試合中PlayerDamageを有効にするかどうか
