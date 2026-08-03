from django.http import JsonResponse
from django.shortcuts import render


def index(request):
    return render(request, "index.html")


def api(request):
    return JsonResponse({"service": "django-container", "status": "ok"})
