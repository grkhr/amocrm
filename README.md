# amocrm

Пакет для работы с [AmoCRM API](https://www.amocrm.ru/developers/content/api/account) в [R](http://www.r-project.org/). 

**UPD**: Так как AmoCRM ввели OAUTH2, а пакет работает на старом методе (токенах) и не переписывался для нового — вот [воркэраунд получения токена](https://hamtim.ru/2020/07/02/как-получить-api-ключ-amocrm/).

Документация и инструкции [**здесь**](#docs). Пожалуйста, **прочтите их** перед началом работы с пакетом. Если возникают проблемы — оформляйте [issue](https://github.com/grkhr/amocrm/issues/new) здесь или пишите в телеграм [@grkhr](https://t.me/grkhr).

**Важно**: База AmoCRM — документоориентированное хранилище, где какому-либо параметру каждой сущности может соответствовать несколько значений (например, мультисписки). Поэтому на выходе не всегда можно сразу получить tidy-датафрейм, рекомендуется разобраться в сущностях и связях AmoCRM перед использованием пакета.

## Установка

```r
#install.packages("devtools")
devtools::install_github("grkhr/amocrm")
```

## Quick start

Для использования пакета нужны e-mail, API-ключ и домен. Их можно найти тут: **xxx.amocrm.ru/settings/profile/**, где **xxx** — ваш поддомен.

**UPD**: Так как AmoCRM ввели OAUTH2, а пакет работает на старом методе (токенах) и не переписывался для нового — вот [воркэраунд получения токена](https://hamtim.ru/2020/07/02/как-получить-api-ключ-amocrm/).

```r
library(amocrm)

# авторизационные данные
auth_list <- AmoAuthList(email = "test@test.ru", apikey = "test", domain = "test")

# получение списка пользователей
users <- AmoUsers(auth_list = auth_list)

# получение сделок
leads <- AmoLeads(auth_list = auth_list)

# получение изменений этапов сделок с 1 июня 2019
notes <- AmoNotes(auth_list = auth_list, type = 'lead', note_type = 3, if_modified_since = '2019-06-01 00:00:00')
```

**Важно**: Все параметры типа datetime возвращаются в таймзоне вашего аккаунта. С фильтрами то же самое. Пакет сам конвертирует время из/в UTC, дополнительных действий не требуется. 

<a name="docs"></a>
## Документация
### Подробное описание функций, параметров и выходных данных

* [Компании - AmoCompanies](md/AmoCompanies.md)
* [Контакты - AmoContacts](md/AmoContacts.md)
* [Покупатели - AmoCustomers](md/AmoCustomers.md)
* [Транзакции покупателей - AmoCustomersTransactions](md/AmoCustomersTransactions.md)
* [Дополнительные поля - AmoCustomFields](md/AmoCustomFields.md)
* [Группы пользователей - AmoGroups](md/AmoGroups.md)
* [Неразобранное - AmoIncomingLeads](md/AmoIncomingLeads.md)
* [Сделки - AmoLeads](md/AmoLeads.md)
* [Примечания / события - AmoNotes](md/AmoNotes.md)
* [Воронки и статусы (этапы) - AmoPipelinesStatuses](md/AmoPipelinesStatuses.md)
* [Задачи - AmoTasks](md/AmoTasks.md)
* [Типы задач - AmoTaskTypes](md/AmoTaskTypes.md)
* [Пользователи - AmoUsers](md/AmoUsers.md)
