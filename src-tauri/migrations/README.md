# migrationsの操作

# migrationsの追加

```sh
cargo sqlx migrate add <simple change msg>
```

# tableのリレーションの可視化

```sh
atlas schema inspect \
        -u "file://migrations" \
        --dev-url "sqlite://file?mode=memory&_fk=1" \
        --web
```

