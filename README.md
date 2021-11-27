# SW_BattleMatchmaker
## 概要
BattleMatchmakerはStormworks WeaponDLCを用いてのTDMを支援するアドオンです。

joinコマンドでプレイヤーがチームに所属すると、状態が画面左に表示されます。
その後readyコマンド全員が準備状態になるとカウントダウンが始まり、試合が開始されます。
時間切れか生存者のいるチームが一つになると試合が終了します。

プレイヤーが死ぬ、プレイヤーに紐付けられた車両が破壊される、コマンドで自殺する、のいずれかでプレイヤーは死亡状態になります。
車両については後述の項目を参照してください。


## コマンド
### プレイヤー用コマンド
プレイヤー用コマンドの実行にはAuthが必要です。

- `?mm`<br>
  コマンド一覧と現在設定を表示
- `?mm reset_ui`<br>
  UI IDを更新する<br>
  joinしても左の状態表示Popupが出ないときに実行してください
- `?mm join (チーム名)`<br>
  チームを作成・参加
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

- `?mm pause`<br>
  制限時間のタイマーを一時停止
- `?mm resume`<br>
  制限時間のタイマーを再開
- `?mm add_time [追加する時間(分)]`<br>
  制限時間を追加
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
チームに所属しているプレイヤーが車両に搭乗すると、その車両は撃破判定管理の対象になります。
車両のHPがゼロになるか、撃破判定用バッテリーが破壊されると車両は撃破状態になります。
プレイヤーが最後に搭乗した車両が撃破されると、プレイヤーは死亡状態になります。

特定の名前（デフォルトでは `killed`）を付けたバッテリーが撃破判定用バッテリーになります。

`gc_vehicle` 設定が有効なとき、撃破された車両は10秒でデスポーンします。

## 弾薬補給
以下のいずれかの名前を付けたボタンを押すことで、プレイヤーの所持品にその弾薬をセットします。

ボタンを車両や拠点に設置することで、弾薬装填を楽しみつつ総残弾を気にせず戦えます。
(HP管理下の車両については、`supply_ammo` 設定の回数だけ弾薬を取得することができます。)

| Weapon Type        |     | Kinetic | High Explosive | Fragmentation | Armor Piercing | Incendiary |
| ------------------ | --- | ------- | -------------- | ------------- | -------------- | ---------- |
| Machine Gun        |     | MG_K    |                |               | MG_AP          | MG_I       |
| Light Auto Cannon  |     | LA_K    | LA_HE          | LA_F          | LA_AP          | LA_I       |
| Rotary Auto Cannon |     | RA_K    | RA_HE          | RA_F          | RA_AP          | RA_I       |
| Heavy Auto Cannon  |     | HA_K    | HA_HE          | HA_F          | HA_AP          | HA_I       |
| Battle Cannon      |     | BS_K    | BS_HE          | BS_F          | BS_AP          | BS_I       |
| Artillery Cannon   |     |         | AS_HE          | AS_F          | AS_AP          |            |


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
- `?mm set battery_name [バッテリー名]`<br>
  車両の撃破判定用バッテリー名を設定
- `?mm set ammo_supply [true|false]`<br>
  弾薬補給を有効にするか設定
- `?mm set ammo_mg/ammo_la/ammo_ra/ammo_ha/ammo_bs/ammo_as [弾薬数]`<br>
  各砲タイプ毎の弾薬補給可能回数を設定<br>
  `-1` を指定すると無限
- `?mm set supply_ammo [補充弾薬数]`<br>
  車両毎の弾薬取得可能回数を設定
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
- `?mm set gc_vehicle`<br>
  撃破車両の自動削除設定
