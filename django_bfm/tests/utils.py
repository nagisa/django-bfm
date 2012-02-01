from django.test import TestCase
from django.test.client import Client


class AuthTestCase(TestCase):
    fixtures = ['testing.json']

    def setUp(self):
        self.client = Client()

    def login_super(self):
        return self.client.login(username='testing', password='testing')

    def login(self):
        return self.client.login(username='testing2', password='testing')
