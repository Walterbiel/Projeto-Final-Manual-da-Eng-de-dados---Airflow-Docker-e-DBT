FROM astrocrpublic.azurecr.io/runtime:3.1-8

RUN python -m venv dbt_venv \
    && . dbt_venv/bin/activate \
    && pip install --no-cache-dir dbt-postgres==1.9.0 \
    && deactivate

