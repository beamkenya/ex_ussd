# ScratchCard
This is ex_ussd example on how to load airtime from a scratch card.

## inspiration
Safaricom (Kenya): Loading airtime through `*141*recharge voucher PIN#`

## install dependence

```elixir
mix deps.get && mix compile
```

## Run Test

```elixir
mix test
```

## Run The Project

```elixir
iex -S mix run --no-halt
```

## Post Request

### Dial *141#

```bash
curl -X POST http://localhost:8080/v1/ussd\?phoneNumber\=254722000000\&sessionId\=session_0001\&serviceCode\=\*141%23\&text\=\*141%23
    
"END You have entered an incorrect format.
Please check and try again. For recharge dial *141*recharge voucher PIN# ok. Thank you"
```

### Dial *141\*1#

```bash
curl -X POST http://localhost:8080/v1/ussd\?phoneNumber\=254722000000\&sessionId\=session_0001\&serviceCode\=\*141%23\&text\=\*141\*1%23

"END Sorry we are unable to complete your request at the moment. Please try again later"
```

### Dial *141\*123456789#

```bash
curl -X POST http://localhost:8080/v1/ussd\?phoneNumber\=254722000000\&sessionId\=session_0001\&serviceCode\=\*141%23\&text\=\*141\*123456789%23

"END Recharge successful"
```