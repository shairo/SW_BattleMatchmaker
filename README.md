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

- `?mm`
  コマンド一覧と現在設定を表示
- `?mm join (チーム名)`
  チームを作成・参加
- `?mm leave`
  チームから離脱
- `?mm ready`
  自分を準備状態に設定
- `?mm wait`
  自分を待機状態に設定
- `?mm die`
  自分を死亡状態に設定（自殺）
- `?mm order`
  車両をプレイヤーの位置にテレポートさせる
- `?resume`
  試合開始前カウントダウンを再開
- `?pause`
  試合開始前カウントダウンを中断
- `?supply`
  準備用の装備品類を設置
- `?delete_supply`
  準備用の装備品類を削除

管理者はjoin/leave/ready/waitコマンドの末尾にpeer_idをつけることで他人をチームに入れたり抜いたりできます。

**現バージョンのStormworksでは、車両テレポートを行うとクライアント側でのみロープが消失します。**
もし困る場合はあらかじめEquipment Inventoryに格納しておくなどすることで回避できます。


### 管理者用コマンド
管理者用コマンドの実行にはAdminが必要です。

- `?mm reset`
  状態をすべてリセット
- `?clear_supply`
  全ての準備用の装備品類を削除
- `?flag [名前]`
  旗を設置
- `?delete_flag [名前]`
  旗を削除
- `?clear_flag`
  すべての旗を削除
- `?mm set_hp [基礎HP]`
  車両の基礎HPを設定
- `?mm set_battery [バッテリー名]`
  車両の撃破判定用バッテリー名を設定
- `?mm set_ammo [補充弾薬数]`
  車両毎の弾薬取得可能回数を設定
- `?mm set_order [true|false]`
  車両テレポートの可否を設定
- `?mm set_cd_time [カウントダウン時間(秒)]`
  カウントダウン時間を設定
- `?mm set_game_time [ゲーム制限時間(分)]`
  ゲーム制限時間を設定
- `?mm set_remind_time [残り時間のリマインド間隔(分)]`
  残り時間のリマインド間隔を設定
- `?mm set_tps [true|false]`
  試合中に三人称視点を許可するかを設定


## 車両について
チームに所属しているプレイヤーが車両に搭乗すると、その車両は撃破判定管理の対象になります。
車両のHPがゼロになるか、撃破判定用バッテリーが破壊されると車両は撃破状態になります。
プレイヤーが最後に搭乗した車両が撃破されると、プレイヤーは死亡状態になります。

## 弾薬補給
以下のいずれかの名前を付けたボタンを押すことで、プレイヤーの所持品にその弾薬をセットします。

ボタンを車両や拠点に設置することで、弾薬装填を楽しみつつ総残弾を気にせず戦えます。
(HP管理下の車両については、setammoコマンドで指定した回数だけ弾薬を取得することができます。)

| Weapon Type        |     | Kinetic | High Explosive | Fragmentation | Armor Piercing | Incendiary |
| ------------------ | --- | ------- | -------------- | ------------- | -------------- | ---------- |
| Machine Gun        |     | MG_K    |                |               | MG_AP          | MG_I       |
| Light Auto Cannon  |     | LA_K    | LA_HE          | LA_F          | LA_AP          | LA_I       |
| Rotary Auto Cannon |     | RA_K    | RA_HE          | RA_F          | RA_AP          | RA_I       |
| Heavy Auto Cannon  |     | HA_K    | HA_HE          | HA_F          | HA_AP          | HA_I       |
| Battle Cannon      |     | BS_K    | BS_HE          | BS_F          | BS_AP          | BS_I       |
| Artillery Cannon   |     |         | AS_HE          | AS_F          | AS_AP          |            |

## 準備用車両
`?mm call_supply` で準備用の装備品類を呼び出せます。
一人一つまでで、試合開始と同時に削除されます。
