import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/6.0/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'django-insecure-6lr-@6g@u40f#($jwj3t3wzdk-24-xg^*+o=)#n3rxvb)_z6n#'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

if DEBUG:
    # Development devices may reach the server from changing local network IPs.
    ALLOWED_HOSTS = ["*"]
else:
    ALLOWED_HOSTS = [
        "127.0.0.1",
        "localhost",
        "10.0.2.2",
    ]


# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.gis',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'accounts.apps.AccountsConfig',
    'admin_portal.apps.AdminPortalConfig',
    'reports.apps.ReportsConfig',
    'rest_framework',
    'rest_framework.authtoken',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'


# Database
# https://docs.djangoproject.com/en/6.0/ref/settings/#databases

import os

DATABASES = {
    "default": {
        "ENGINE": "django.contrib.gis.db.backends.postgis",
        "NAME": os.environ.get("DB_NAME", "women_safety"),
        "USER": os.environ.get("DB_USER", "postgres"),
        "PASSWORD": os.environ.get("DB_PASSWORD", "12345678!@#$%^&*"),
        "HOST": os.environ.get("DB_HOST", "127.0.0.1"),
        "PORT": os.environ.get("DB_PORT", "5432"),
    }
}



# Keep local demo logins responsive. Django can still verify older hashes
# because the previous default hashers remain listed after PBKDF2.
if DEBUG:
    PASSWORD_HASHERS = [
        'config.hashers.FastDevPBKDF2PasswordHasher',
        'django.contrib.auth.hashers.PBKDF2PasswordHasher',
        'django.contrib.auth.hashers.PBKDF2SHA1PasswordHasher',
        'django.contrib.auth.hashers.ScryptPasswordHasher',
    ]


# Password validation
# https://docs.djangoproject.com/en/6.0/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/6.0/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/6.0/howto/static-files/

STATIC_URL = 'static/'


DEFAULT_GOOGLE_OAUTH_CLIENT_IDS = [
    # "1234567890-abc.apps.googleusercontent.com",
]
_google_client_ids = os.getenv("GOOGLE_OAUTH_CLIENT_IDS") or os.getenv(
    "GOOGLE_OAUTH_CLIENT_ID", ""
)
GOOGLE_OAUTH_CLIENT_IDS = [
    value.strip()
    for value in _google_client_ids.split(",")
    if value.strip()
]
if not GOOGLE_OAUTH_CLIENT_IDS:
    GOOGLE_OAUTH_CLIENT_IDS = DEFAULT_GOOGLE_OAUTH_CLIENT_IDS
