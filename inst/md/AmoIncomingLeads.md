# AmoIncomingLeads — Неразобранное

[Официальная документация AmoCRM, описание полей](https://www.amocrm.ru/developers/content/api/unsorted)

## Пример использования

```r
library(amocrm)

# получение всех сделок из неразобранного
incleads <- AmoIncomingLeads(auth_list = auth_list)

# с фильтрами
incleads_filtered <- AmoIncomingLeads(auth_list = auth_list,
                              categories = c('sip','mail'),
                              order_by_key = 'created_at',
                              order_by_value = 'desc')
```

## Параметры запроса

Параметр | Описание
 --- | ---
email | **Обязательный**. Ваш e-mail. **Можно не указывать, если указан** `auth_list`.
apikey | **Обязательный**. Ваш API-ключ. **Можно не указывать, если указан** `auth_list`.
domain | **Обязательный**. Ваш поддомен. **Можно не указывать, если указан** `auth_list`.
auth_list | **Обязательный**. Лист с авторизационными данными, подробнее `?AmoAuthList`. **Можно не указывать, если указаны три параметра выше**.
limit | Батчинг запросов. По дефолту 500. Иногда AmoCRM API лагает и не отдает данные, в таких случаях можно попробовать уменьшить этот параметр.
categories | Фильтр. Категории. "sip", "mail", "forms" и "chats". Можно передавать вектором.
order_by_key | Фильтр. Ключ, по которому будет происходить сортировка. Например, `created_at`
order_by_value | Фильтр. Направление сортировки. `asc` или `desc`
pipeline_id | Фильтр. Принимает ID воронки. ID воронок можно получить с помощью AmoPipelinesStatuses().