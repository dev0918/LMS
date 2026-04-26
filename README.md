# Zyneriq

Zyneriq is a Django-based learning management system for managing students,
lecturers, programs, courses, sessions, semesters, quizzes, assessments, and
results.

## Features--

- Admin dashboard for school analytics
- Student, lecturer, session, semester, program, and course management
- Guest student signup with admin approval
- Course allocation and student course registration
- Quiz, assessment, and grade result workflows
- PDF generation for student records and reports
- Role-based page access for admins, lecturers, students, and parents

## Requirements

- Python 3.8+

## Installation

Create and activate a virtual environment, then install dependencies:

```bash
pip install -r requirements.txt
```

Create a `.env` file in the project root. You can start from `.env.example`
and customize the values for your deployment.

Run the database migrations:

```bash
python manage.py migrate
```

Create an admin user:

```bash
python manage.py createsuperuser
```

Start the development server:

```bash
python manage.py runserver
```

Open the app at:

```text
http://127.0.0.1:8000
```

## Deployment Notes

Before hosting, set production-ready values for `SECRET_KEY`, `DEBUG`,
`ALLOWED_HOSTS`, email settings, static files, and database configuration.

## License

This project includes open-source code and third-party assets governed by their
respective licenses. Zyneriq-specific customizations and deployment branding are
owned by Zyneriq.
