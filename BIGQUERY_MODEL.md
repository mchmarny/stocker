# stocker ML

Stocker model


## Create Model

```sql
#standardSQL
CREATE OR REPLACE MODEL stocker.price_model
OPTIONS
  (model_type='linear_reg', input_label_cols=['price']) AS
SELECT
  p.price,
  p.closingPrice as prev_price,
  c.symbol,
  c.magnitude * c.score as sentiment,
  CAST(c.retweet AS INT64) as retweet
FROM stocker.content c
JOIN stocker.price p on c.symbol = p.symbol
  AND FORMAT_TIMESTAMP('%Y-%m-%d', c.created) = FORMAT_TIMESTAMP('%Y-%m-%d', p.quotedAt)
WHERE c.score <> 0
AND RAND() < 0.02
```

results in

```shell
This statement created a new model named stocker.price_model
```


## Evaluate model

```sql
#standardSQL
INSERT stocker.price_mode_eval (
   eval_ts,
   mean_absolute_error,
   mean_squared_error,
   mean_squared_log_error,
   median_absolute_error,
   r2_score,
   explained_variance
) WITH T AS (
  SELECT
    *
  FROM
    ML.EVALUATE(MODEL stocker.price_model,(
      SELECT
        p.price,
        p.closingPrice as prev_price,
        c.symbol,
        c.magnitude * c.score as sentiment,
        CAST(c.retweet AS INT64) as retweet
      FROM stocker.content c
      JOIN stocker.price p on c.symbol = p.symbol
        AND FORMAT_TIMESTAMP('%Y-%m-%d', c.created) = FORMAT_TIMESTAMP('%Y-%m-%d', p.quotedAt)
      WHERE c.score <> 0
  ))
)
SELECT
  CURRENT_TIMESTAMP(),
  mean_absolute_error,
  mean_squared_error,
  mean_squared_log_error,
  median_absolute_error,
  r2_score,
  explained_variance
FROM T
```

results in

```shell
mean_absolute_error	 mean_squared_error	 mean_squared_log_error	 median_absolute_error	r2_score            explained_variance
3.2502161606238453   227.0738450661901   0.008387276788977339    0.12880176496196327    0.9990422574648288  0.999079865551752
```

> The R2 score is a statistical measure that determines if the linear regression predictions approximate the actual data. 0 indicates that the model explains none of the variability of the response data around the mean. 1 indicates that the model explains all the variability of the response data around the mean.

# Use your model to predict stock price

```sql
#standardSQL
INSERT stocker.price_prediction (
   symbol,
   after_closing_price,
   predicted_price
) WITH T AS (

  SELECT
      dt.symbol as symbol,
      p.closingPrice as after_closing_price,
      ROUND(AVG(dt.predicted_price),2) as predicted_price
  FROM
    ML.PREDICT(MODEL stocker.price_model,
      (
      SELECT
        p.price,
        p.closingPrice as prev_price,
        c.symbol,
        c.magnitude * c.score as sentiment,
        CAST(c.retweet AS INT64) as retweet
      FROM stocker.content c
      JOIN stocker.price p on c.symbol = p.symbol
        AND FORMAT_TIMESTAMP('%Y-%m-%d', c.created) = FORMAT_TIMESTAMP('%Y-%m-%d', p.quotedAt)
  )) dt
  join stocker.price p on p.symbol =  dt.symbol
  where p.closingDate = FORMAT_TIMESTAMP('%Y-%m-%d', CURRENT_TIMESTAMP()) -- assumes after market close exec
  group by
    dt.symbol,
    p.closingPrice

)
SELECT
   symbol,
   after_closing_price,
   predicted_price
FROM T
```

