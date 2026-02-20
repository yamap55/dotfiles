---
name: sql
description: SQLクエリを記述する際のフォーマットルールを適用するスキル。ユーザーがSQLの作成・修正・確認を依頼した場合に使用する。
---

# SQL フォーマットルール

このスキルが呼び出されたら、以降のSQL出力にすべて下記ルールを適用すること。

## 基本

- キーワード（`SELECT`, `FROM`, `WHERE`, `JOIN`, `ON`, `AS`, `WITH`, `AND`, `OR` 等）はすべて大文字
- 各句キーワード（`SELECT` / `FROM` / `WHERE` / `WITH` 等）はインデントなしで行頭に記述
- インデントは2スペース

## SELECT句

- カラムは1行ずつ2スペースインデント
- 2列目以降は**行頭カンマ**（comma-first）: `  , column`
- エイリアスには必ず `AS` を使用
- 日本語など特殊な列名はバッククォートで囲む

## FROM句 / JOIN

- テーブル名は `FROM` の次の行に2スペースインデント
- `JOIN` も同じインデントレベル（2スペースインデント）
- `ON` 条件は `JOIN` と同じ行に記述
- テーブルには短いアルファベットのエイリアスをつける

## WHERE句

- 各条件を1行ずつ2スペースインデント
- 2条件目以降は行頭に `AND` / `OR` を置く

## WITH句（CTE）とサブクエリ

- 複雑なサブクエリはインラインサブクエリより **WITH句を優先** して使う
- **1行で書ける程度のサブクエリはインラインで記述してよい**（フォーマット規則は適用しない）
- CTE内部も同じフォーマット規則に従う

## サンプル

```sql
WITH target_user AS (
  SELECT
    *
  FROM
    user u
  WHERE
    u.created_at >= '2025-01-01'
)
SELECT
  tu.id AS user_id
  , tu.name AS `ユーザー名`
  , ud.age
FROM
  target_user tu
  INNER JOIN user_detail ud ON tu.id = ud.user_id
WHERE
  tu.name IN ('abc', 'xyz')
  AND ud.age > 20
```
