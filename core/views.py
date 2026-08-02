from django.http import JsonResponse


def index(request):
    return JsonResponse({"service": "django-container", "status": "ok"})
