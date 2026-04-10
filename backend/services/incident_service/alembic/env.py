import os
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
from geoalchemy2 import Geometry
from alembic.autogenerate import renderers
from alembic.autogenerate import comparators

# Tell Alembic to recognize Geometry columns and not touch them unless they actually changed
import geoalchemy2.alembic_helpers  # noqa: F401 — registers the hooks automatically

# ── Import your models so Alembic can see the metadata ──
from app.models.incident import Incident  # noqa: F401 — import triggers model registration
from app.database import Base

# Alembic Config object
config = context.config

# Set up Python logging from alembic.ini
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# This is the metadata Alembic will diff against the real DB
target_metadata = Base.metadata

# ── Inject the DB URL from environment at runtime ──
# docker-compose sets INCIDENT_DATABASE_URL_SYNC (psycopg2, synchronous)
def get_url() -> str:
    url = os.environ.get("INCIDENT_DATABASE_URL_SYNC")
    if not url:
        raise RuntimeError("INCIDENT_DATABASE_URL_SYNC environment variable not set")
    return url


# In env.py, replace your run_migrations_online() and run_migrations_offline() 
# with this updated version:

def include_object(object, name, type_, reflected, compare_to):
    """
    Exclude PostGIS system tables, Tiger geocoder tables, and topology tables.
    Only manage objects in the 'public' schema that belong to your app.
    """
    # Exclude entire schemas
    if hasattr(object, 'schema') and object.schema in ('tiger', 'topology'):
        return False
    
    # Exclude specific PostGIS system tables in public schema
    excluded_tables = {
        'spatial_ref_sys',
        'geometry_columns', 
        'geography_columns',
        'raster_columns',
        'raster_overviews',
        # Tiger geocoder tables that land in public
        'zip_state_loc', 'zip_lookup', 'zip_state', 'zip_lookup_all',
        'zip_lookup_base', 'county_lookup', 'place_lookup', 'countysub_lookup',
        'state_lookup', 'street_type_lookup', 'secondary_unit_lookup',
        'direction_lookup', 'geocode_settings', 'geocode_settings_default',
        'loader_platform', 'loader_variables', 'loader_lookuptables',
        'pagc_lex', 'pagc_gaz', 'pagc_rules',
        'faces', 'edges', 'addrfeat', 'featnames', 'addr',
        'bg', 'tabblock', 'tabblock20', 'tract', 'cousub', 'county',
        'state', 'place', 'zcta5', 'topology', 'layer',
    }
    if type_ == 'table' and name in excluded_tables:
        return False

    return True


def include_schemas(names):
    """Only inspect the public schema."""
    return {'public'}


def run_migrations_offline() -> None:
    url = get_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        include_object=include_object,
        include_schemas=False,  # ← don't scan tiger/topology schemas
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    configuration = config.get_section(config.config_ini_section, {})
    configuration["sqlalchemy.url"] = get_url()

    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            include_object=include_object,   # ← filters out PostGIS junk
            include_schemas=False,           # ← don't scan other schemas
        )
        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online() 