from django.http import HttpResponse


class HealthCheckMiddleware:
    """
    Health check that supports AWS ALB requets.
    
    ALB health-checks a target by its private IP, so its `Host` header
    might not be in `ALLOWED_HOSTS`. Instead of adding values to
    `ALLOWED_HOSTS`, respond to the health check directly via `__call__`,
    before any middleware calls `request.get_host()`.
    """
    HEALTH_CHECK_PATH = "/health"

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.path in (self.HEALTH_CHECK_PATH, f"{self.HEALTH_CHECK_PATH}/"):
            return HttpResponse("ok", content_type="text/plain")
        return self.get_response(request)
