from django.contrib.auth.hashers import PBKDF2PasswordHasher


class FastDevPBKDF2PasswordHasher(PBKDF2PasswordHasher):
    """Lower-cost hasher for local demo/dev logins only."""

    iterations = 120_000
