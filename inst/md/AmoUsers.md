# AmoUsers — Пользователи

[Официальная документация AmoCRM, описание полей](https://www.amocrm.ru/developers/content/api/account)

## Пример использования

```r
library(amocrm)

# получение пользователей
users <- AmoUsers(auth_list = auth_list)
```
## Параметры ответа

```r
> users

        id                       name last_name                       login language group_id is_active is_free is_admin phone_number
1  2266552             Тестовый юзер1      <NA>               test1@test.ru       ru        0      TRUE   FALSE     TRUE  89117111666
2  2347048             Тестовый юзер2      <NA>               test2@test.ru       ru        0      TRUE   FALSE     TRUE         <NA>
3  2750983             Тестовый юзер3      <NA>               test3@test.ru       ru        0      TRUE   FALSE    FALSE         <NA>
4  2862925             Тестовый юзер4      <NA>               test4@test.ru       ru        0      TRUE   FALSE     TRUE         <NA>
5  2929396             Тестовый юзер5      <NA>               test5@test.ru       ru        0      TRUE   FALSE    FALSE         <NA>
```

## Параметры запроса

Параметр | Описание
 --- | ---
email | **Обязательный**. Ваш e-mail. **Можно не указывать, если указан** `auth_list`.
apikey | **Обязательный**. Ваш API-ключ. **Можно не указывать, если указан** `auth_list`.
domain | **Обязательный**. Ваш поддомен. **Можно не указывать, если указан** `auth_list`.
auth_list | **Обязательный**. Лист с авторизационными данными, подробнее `?AmoAuthList`. **Можно не указывать, если указаны три параметра выше**.
