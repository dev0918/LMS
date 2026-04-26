from django.apps import AppConfig


class JetConfig(AppConfig):
    default_auto_field = "django.db.models.AutoField"
    name = "jet"


class JetDashboardConfig(AppConfig):
    default_auto_field = "django.db.models.AutoField"
    name = "jet.dashboard"
