# otus_crawler
Проект микросервисного приложения по парсингу сайтов

### Порядок запуска проекта
- **Создание кластера Kubernetes**
   - Создается кластер на 3 ноды (количество нод задается через переменную var.cluster_node_count)
   - Создаются необходимые правила firewall
   - Создается Service account `tiller`
   - Сервис аккаунту присваивается роль `cluster-admin`
   - В кластер устанавливается приложение Gitlab-omnibus (через helm chart)
```
$ cd terraform && terraform apply
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
   - ___rewiew___ - на данном этапе устанавливаем зависимости, создаем отдельный namespace review в kubernetes, устанавливаем tiller и производим установку chart приложения
   - ___cleanup___ - после проведения review удаляем helm chart приложения (ручной режим запуска)
   ##### Для Master ветки
   - ___release___ - на данном этапе берем образ из докерхаб, устанавливаем тэг с номером релиза и рушим докр образ в докерхаб
   - ___production___ - создаем отдельный namespace production в kubernetes и устанавливаем в него chart с приложением (ручной режим запуска)

   #### Pipeline для Crawler-Deploy состоит из следующих этапов:
   - ___test___ - на данном этапе проводится скачивание и тестирование готовых сборок докер образов crawler и crawler-ui
   - ___staging___ - на данном этапе устанавливаем зависимости, создаем отдельный namespace **staging** в kubernetes, устанавливаем tiller и производим установку chart приложения на тестовое окружение
   - ___production___ - на данном этапе устанавливаем зависимости, создаем отдельный namespace **production** в kubernetes, устанавливаем tiller и производим установку chart приложения на продакшн окружение

----
## Backlog
- **Мониторинг**. 
   - Организация сбора метрик кластера с помощью Prometheus. 
   - Разработка необходимых дашбордов Grafana. 
   - Алертинг оповещение о событиях в кластере (slack, email)
- **Логирование**. Организация сбора логов микросервисов системой EFK.
- **Трейсинг** - по возможности
- **ChatOps** - по возможности




----
### CHANGELOG
#### v.0.0.1 - Локальная разработка
- Создал docker образы для бэкенда (crawler) и фронтэнда (ui). Для запуска тестов собранных образов было принято решения собрать обрызы приложений сразу с тестами.
- Создал docker-compose файлы для запуска приложения в локальной среде
- Запустил Gitlab-ci в докере на локальной машине
- Разработал gitlab-ci.yml для пайплайна сборки и тестирования докер образа микросервиса **ui**.
#### v.0.0.2 - Подготовка кластера Kubernetes на GCP
Создал сценарий terraform для создания кластера. Для постоянного хранения данных Gitlab решил создать внешнюю БД PostgreSQL с хранением данных на отдельном диске
```
## Создадим диск для Gitlab PostgreSQL
$ gcloud compute disks create --size=30GB --zone=europe-west1-b --type=pd-ssd gitlab-postgresql-disk
## Создание кластера
$ cd terraform && terraform init
$ terraform apply
```
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
#### v.0.0.8 - Pipeline для запуска приложения на review и production