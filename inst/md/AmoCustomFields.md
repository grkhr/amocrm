# AmoCustomFields — Дополнительные поля

[Официальная документация AmoCRM, описание полей](https://www.amocrm.ru/developers/content/api/account)

## Пример использования

```r
library(amocrm)

# получение дополнительных полей
cf <- AmoCustomFields(auth_list = auth_list)

# информация по доп. полям контактов
cf_contacts <- cf$custom_fields_contacts$custom_fields

# информация по значениям доп. полей контактов включая мультисписки
cf_contacts_enum <- cf$custom_fields_contacts$custom_fields_enum

# джойн двух датафреймов выше, на выходе строка будет соответствовать каждому значению доп. поля
cf_contacts_flatteb <- dplyr::left_join(cf_contacts, cf_contacts_enum, by = "id")
```
## Параметры ответа

Рекомендуется прочесть официальную документацию для понимания структуры данных дополнительных полей.

Лист | Подлист | Описание
 --- | --- | ---
custom_fields_contacts | custom_fields | Дополнительные поля контакта, основная информация
custom_fields_contacts | custom_fields_enum  | Значения дополнительных полей, мультисписки (enum — доп. значения доп. полей)
custom_fields_leads | custom_fields | Дополнительные поля сделки, основная информация
custom_fields_leads | custom_fields_enum  | Значения дополнительных полей, мультисписки (enum — доп. значения доп. полей)
custom_fields_companies | custom_fields | Дополнительные поля компании, основная информация
custom_fields_companies | custom_fields_enum  | Значения дополнительных полей, мультисписки (enum — доп. значения доп. полей)
custom_fields_customers | custom_fields | Дополнительные поля покупателя, основная информация
custom_fields_customers | custom_fields_enum  | Значения дополнительных полей, мультисписки (enum — доп. значения доп. полей)

```r
> cf$custom_fields_contacts$custom_fields

       id name                     field_type  sort code           is_multiple is_system is_editable is_required is_deletable is_visible
    <int> <chr>                         <int> <int> <chr>          <lgl>       <lgl>     <lgl>       <lgl>       <lgl>        <lgl>     
 1  59593 Должность                         1     8 POSITION       FALSE       TRUE      TRUE        FALSE       TRUE         TRUE      
 2  59595 Телефон                           8     4 PHONE          TRUE        TRUE      TRUE        FALSE       TRUE         TRUE      
 3  59597 Email                             8     6 EMAIL          TRUE        TRUE      TRUE        FALSE       TRUE         TRUE      
 4  59601 Мгн. сообщения                    8     9 IM             TRUE        TRUE      TRUE        FALSE       TRUE         TRUE      
 5 108995 CF_NAME_USER_AGREEMENT            3    10 USER_AGREEMENT FALSE       TRUE      FALSE       FALSE       TRUE         TRUE      
 6 272109 Группа пользователей              4   511 NA             FALSE       FALSE     TRUE        FALSE       TRUE         TRUE      
 7 297293 Номер линии MANGO OFFICE          1   507 NA             FALSE       FALSE     FALSE       FALSE       TRUE         TRUE      
 8 325653 ВКонтакте                         7   512 NA             FALSE       FALSE     TRUE        FALSE       TRUE         TRUE      
 9 325655 Одноклассники                     7   513 NA             FALSE       FALSE     TRUE        FALSE       TRUE         TRUE      
10 325657 Facebook                          7   514 NA             FALSE       FALSE     TRUE        FALSE       TRUE         TRUE  

> cf$custom_fields_contacts$custom_fields_enum

       id                 name enum_id             enum_name
1   59595              Телефон  127703                  WORK
2   59595              Телефон  127705                WORKDD
3   59595              Телефон  127707                   MOB
4   59595              Телефон  127709                   FAX
5   59595              Телефон  127711                  HOME
6   59595              Телефон  127713                 OTHER
7   59597                Email  127715                  WORK
8   59597                Email  127717                  PRIV
9   59597                Email  127719                 OTHER
10  59601       Мгн. сообщения  127721                 SKYPE
```

## Параметры запроса

Параметр | Описание
 --- | ---
email | **Обязательный**. Ваш e-mail. **Можно не указывать, если указан** `auth_list`.
apikey | **Обязательный**. Ваш API-ключ. **Можно не указывать, если указан** `auth_list`.
domain | **Обязательный**. Ваш поддомен. **Можно не указывать, если указан** `auth_list`.
auth_list | **Обязательный**. Лист с авторизационными данными, подробнее `?AmoAuthList`. **Можно не указывать, если указаны три параметра выше**.
