# otus_crawler
Проект микросервисного приложения по парсингу сайтов

### Необходимое ПО (на локальной машине)
Для установки проекта на локальной машине потребуется следующее ПО
- Terraform
- gcloud
- helm
- kubectl
- git


### Порядок запуска проекта
- **Создание кластера Kubernetes**
   - Создается кластер на 3 ноды (количество нод задается через переменную var.cluster_node_count)
   - Также для Elasticsearch создается отдельный пулл повышенной мощности `n1-standart-2`
   - Создаются необходимые правила firewall
   - Создается Service account `tiller`
   - Сервис аккаунту присваивается роль `cluster-admin`
   - В кластер устанавливается helm chart приложения
     - Gitlab-omnibus
     - Prometheus
     - EFK (Elasticsearch - Fluentd - Kibana)
     - Grafana
     - Kibana
   - Хранение файла состояния terraform.tfstate вынесено в бакет
```
$ cd terraform && terraform init && terraform apply
```
- **Подключение к кластеру**
   - Для подключения к кластеру смотрим IP адрес ingress nginx
   ```
   $ kubectl get service -n nginx-ingress nginx
   ``` 
   - И прописываем его в hosts
   ```
   ## Файл /etc/hosts
   10.10.10.10  gitlab-gitlab production staging crawler-prometheus crawler-grafana crawler-kibana
   ```

- **Настройка Gitlab**
   - Создаем группу для проектов
   - Добавляем в настройках группы 2 переменные для доступа к докерхаб (CI_REGISTRY_USER и CI_REGISTRY_PASSWORD)
   - Создадим 3 проекта: crawler, crawler-ui и crawler-deploy
      Инициализируем репозиторий для CRAWLER
      ```
      $ cd search_engine_crawler
      $ git init
      $ git remote add origin http://gitlab-gitlab/boygruv/crawler.git
      $ git add .
      $ git commit -m "Initial commit"
      $ git push -u origin master
      ```
      Инициализируем репозиторий для UI
      ```
      $ cd search_engine_ui
      $ git init
      $ git remote add origin http://gitlab-gitlab/boygruv/crawler-ui.git
      $ git add .
      $ git commit -m "Initial commit"
      $ git push -u origin master
      ```
      Инициализируем репозиторий для CRAWLER-DEPLOY
      ```
      $ cd crawler_deploy
      $ git init
      $ git remote add origin http://gitlab-gitlab/boygruv/crawler-deploy.git
      $ git add .
      $ git commit -m "Initial commit"
      $ git push -u origin master
      ```
- #### Описание Pipeline

   ##### Pipeline Crawler и Crawler-UI состоит из следующих этапов:
   ##### Для Feature веток
   - ___build___ - на данном этапе мы собираем докер образ и заливаем его на докерхаб
   - ___test___ - на данном этаме берем собранный на предидущем этапе образ с докерхаба и запускаем на нем тесты
   - ___rewiew___ - на данном этапе устанавливаем зависимости, создаем отдельный namespace review в kubernetes, устанавливаем tiller и производим установку chart приложения на окружение с названием ветки
   - ___cleanup___ - после проведения review удаляем helm chart приложения (ручной режим запуска)
   ##### Для Master ветки
   - ___build___ - на данном этапе мы собираем докер образ и заливаем его на докерхаб
   - ___test___ - на данном этаме берем собранный на предидущем этапе образ с докерхаба и запускаем на нем тесты
   - ___release___ - на данном этапе берем образ из докерхаб, устанавливаем тэг с номером релиза (файл VERSION) и рушим докр образ в докерхаб
   - ___deploy___ - на данном этапе можно выкатить приложение на **production** или **staging** окружения (ручной режим запуска)

   #### Pipeline для Crawler-Deploy состоит из следующих этапов:
   - ___staging___ - на данном этапе устанавливаем зависимости, создаем отдельный namespace **staging** в kubernetes, устанавливаем tiller и производим установку chart приложения на тестовое окружение
   - ___production___ - на данном этапе устанавливаем зависимости, создаем отдельный namespace **production** в kubernetes, устанавливаем tiller и производим установку chart приложения на продакшн окружение

### Мониторинг 
   - Мониторинг организован при помощи Prometheus.
   - Визуализация метрик Grafana. Разработанны дашбоард и датасоурс автоматически провижинится при инсталляции. 
   - В разработанном дашборде добавлена возможность для выбора разных namespace.
   - Алертинг. Оргинизовано оповещение о падении подов в канал slack: https://boygruv.slack.com/messages/GBCSK40P3/

### Логирование. Организация сбора логов микросервисов системой EFK.
   - Для логирования микросервисов был разработан собственный helm chart: EFK поднимающий БД Elasticsearch и Fluentd DaemonSet.
   - Kibana устанавливантся отдельно из публичного репозитория.
   - Для просмотра логов в Kibana добавляем индекс fluentd-*
   - И фильтр для примера: `kubernetes.namespace_name: production AND kubernetes.labels.app: crawler-ui`



----
### CHANGELOG
#### v.0.0.1 - Локальная разработка
- Создал docker образы для бэкенда (crawler) и фронтэнда (ui)
- Создал docker-compose файлы для запуска приложения в локальной среде
- Запустил Gitlab-ci в докере на локальной машине
- Разработал gitlab-ci.yml для пайплайна сборки и тестирования докер образа микросервиса **ui**.
#### v.0.0.2 - Удален

#### v.0.0.3 - Tiller (серверная часть Helm)
Установка
```
## Подключимся к кластеру
$ gcloud container clusters get-credentials crawler-cluster --zone europe-west1-b --project docker-223416 
$ helm init --service-account tiller
## проверка
$ kubectl get pods -n kube-system --selector app=helm
```
###3 v.0.0.4 - Chart пакет Helm
```
## Установка Gitlab
$ cd chart/gitlab-omnibus/ 
$ helm install --name gitlab . -f values.yaml

## Посмотрим IP адрес Ingress
$ kubectl get service  -n nginx-ingress nginx
## Пропишем IP адрес в /etc/hosts

## Ждем пока поднимутся все Gitlab поды
$ kubectl get pods
```
#### v.0.0.5 - Gitlab
- При создании группы добавим переменные (CI_REGISTRY_USER и CI_REGISTRY_PASSWORD) для доступа к репозиторию Docker Hub
- Создадим 3 проекта: crawler, crawler-ui и crawler-deploy
- Инициализируем репозиторий для CRAWLER
```
$ cd search_engine_crawler
$ git init
$ git remote add origin http://gitlab-gitlab/boygruv/crawler.git
$ git add .
$ git commit -m "Initial commit"
$ git push -u origin master
```
- Инициализируем репозиторий для UI
```
$ cd search_engine_ui
$ git init
$ git remote add origin http://gitlab-gitlab/boygruv/crawler-ui.git
$ git add .
$ git commit -m "Initial commit"
$ git push -u origin master
```
- Инициализируем репозиторий для CRAWLER-DEPLOY
```
$ cd crawler_deploy
$ git init
$ git remote add origin http://gitlab-gitlab/boygruv/crawler-deploy.git
$ git add .
$ git commit -m "Initial commit"
$ git push -u origin master
```
- Backup & Restore Gitlab
```
$ kubectl exec -t gitlab-gitlab-5fbf8b57c8-b726h gitlab-rake gitlab:backup:create SKIP=uploads,buids,artifacts,lfs,registry,pages
1550090203_2019_02_13_10.6.2_gitlab_backup.tar

$ kubectl exec -it gitlab-gitlab-5fbf8b57c8-b726h  gitlab-rake gitlab:backup:restore   
```

#### v.0.0.6 - Pipeline
**Pipeline состоит из следующих этапов:**
   #### Для Feature веток
   - **build** - на данном этапе мы собираем докер образ и заливаем его на докерхаб
   - **test** - на данном этаме берем собранный на предидущем этапе образ с докерхаба и запускаем на нем тесты
   - **rewiew** - на данном этапе устанавливаем зависимости, создаем отдельный namespace review в kubernetes, устанавливаем tiller и производим установку chart приложения
   - **cleanup** - после проведения review удаляем helm chart приложения (ручной режим запуска)
   #### Для Master ветки
   - **release** - на данном этапе берем образ из докерхаб, устанавливаем тэг с номером релиза и рушим докр образ в докерхаб
   - **production** - создаем отдельный namespace production в kubernetes и устанавливаем в него chart с приложением (ручной режим запуска)
#### v.0.0.7 - Helm Chart
```
# Посомтрим доступные чарты для mongodb и rabbitmq
$ helm search mongodb
$ helm search rabbitmq
# скачать зависимости
$ helm dep update
# Установка приложения
$ helm install crawler --name crawler-test 
# Обновить микросервис
$ helm dep update ./grabber 
$ helm upgrade crawler-test ./grabber
# Удалить приложение
$ helm del --purge crawler-test
```

#### v.0.0.8 - Мониторинг
- Добавил в манифест терраформа инсталляцию Prometheus и Grafana. Пароль для Grafana (admin:admin)
- Добавил в конфиг Prometheus джоб crawler-endpoints для выборки приложения по label app=crawler
- Создал датасоурс и дашбоард для графаны. В дашборде добавил возможность фильтра метрик по namespace
- Добавил провиженинг в графане для автоматического создания датасоурс и дашбоард

#### v.0.0.9 - Алертинг
- Включил Alertmanager
- Прописал правила для срабатывания алертов: 
   - падение пода InstanceDown в течении минуты
- Настроил оповещение в Slack канал: https://boygruv.slack.com/messages/GBCSK40P3/ 

#### v.0.0.10 - Логирование
- Добавил helm chart для запуска EFK и Kibana
- Для Elasticsearch добавил отдельный инстанс и пометил label = elastichost 
- Для просмотра логов в Kibana добавляем индекс fluentd-*

#### v.0.0.11 - Тестирование кода в докер контейнере
- Вынес тесты из докер контейнера. Тестирование проводится путем монтирования каталога с тестами к контейнеру и последующим запуском тестов
- Вынес хранение файла состояния terraform.tfstate в бакет
