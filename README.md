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
生存者がいるチームが一つ以下になると試合終了します。
管理者が `?mm abort` で試合を中止することもできます。

プレイヤーのDead状態は `?mm wait` や `?mm join` などでリセットできます。
また管理者が `?mm reset` するとすべてのチームを解散します。

### 管理者向けTips
admin権限のあるユーザーはより細かいコマンドオプションが使えます。

- `?mm flag [名前]` で今いる場所に旗を立てることができます。旗はマップから確認できるので、スタート地点を指定するのに使えます
- `?mm join` などのコマンドは、末尾にpeer_idを指定することで他人を操作できます
- `?mm shuffle [チーム数(2-4)]` でjoin済プレイヤーを適当にチーム分けできます
- 全員readyしていなくても `?mm start` で試合を開始できます
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
- `?mm supply`<br>
  準備用の装備品類を設置
- `?mm delete_supply`<br>
  準備用の装備品類を削除

管理者はjoin/leave/ready/waitコマンドの末尾にpeer_idをつけることで他人をチームに入れたり抜いたりできます。

### 管理者用コマンド
管理者用コマンドの実行にはAdminが必要です。

- `?mm start`<br>
  join済のユーザーを全員readyして試合開始
- `?mm abort`<br>
  試合を中止
- `?mm pause`<br>
  制限時間のタイマーを一時停止
- `?mm resume`<br>
  制限時間のタイマーを再開
- `?mm add_time [追加する時間(分)]`<br>
  制限時間を追加
- `?mm shuffle [チーム数(2-4)]`<br>
  ランダムにチーム分け
- `?mm dismiss [チーム名]`<br>
  チームを解散
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


## 装備品類の呼び出し
`?mm supply` で準備用の装備品類を呼び出せます。
一人一つまで呼び出す事が可能で、試合開始と同時に削除されます。


## 旗の設置
管理者は `?mm flag (名前)` で旗を設置できます。
旗はマップ画面から視認可能です。集合場所の設定などに使用してください。


## 変更可能な設定
管理者は `?mm set` コマンドでゲームの設定を変更することができます。

- `?mm set vehicle_hp [HP]`<br>
  車両の初期HP(非クラス制時)
- `?mm set vehicle_class [true|false]`<br>
  クラス制を有効にする
- `?mm set max_damage [ダメージ量]`<br>
  1tickに受けられる最大ダメージ量
- `?mm set ammo_supply [true|false]`<br>
  弾薬補給を有効にする
- `?mm set ammo_mg/ammo_la/ammo_ra/ammo_ha/ammo_bs/ammo_as [弾薬数]`<br>
  各砲タイプ毎の弾薬補給可能回数<br>
  `-1` を指定すると無限
- `?mm set game_time [ゲーム制限時間(分)]`<br>
  ゲーム制限時間
- `?mm set order_enabled [true|false]`<br>
  試合中に車両テレポートを許可する
- `?mm set tps_enabled [true|false]`<br>
  試合中に三人称視点を許可する
- `?mm set player_damage [true|false]`<br>
  試合中にPlayerDamageを有効にする
- `?mm set gc_vehicle [true|false]`<br>
  撃破車両を自動削除する
- `?mm set auto_standby [true|false]`<br>
  試合終了後にプレイヤー全員をWait状態にする
- `?mm set auto_auth [true|false]`<br>
  プレイヤー参加時に自動でadd authする
