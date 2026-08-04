from django.test import Client, TestCase, override_settings


class HealthCheckTests(TestCase):
    def test_health_check_responds_ok(self):
        response = self.client.get("/health/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content, b"ok")

    def test_health_check_bypasses_allowed_hosts(self):
        """The ALB health-checks by target IP, which is never an allowed host."""
        with self.settings(ALLOWED_HOSTS=["example.com"]):
            response = Client(headers={"host": "10.0.1.55"}).get("/health/")
        self.assertEqual(response.status_code, 200)


@override_settings(
    STORAGES={
        "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
    }
)
class IndexTests(TestCase):
    def test_index_returns_pk(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
