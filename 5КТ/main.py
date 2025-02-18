import psycopg2
import pandas as pd

# Удалённая БД
REMOTE_DB_CONFIG = {
    'dbname': 'home',
    'user': 'student',
    'password': 'gendalfthegreat',
    'host': '212.8.247.94',
    'port': '5432'
}

# Локальная БД
LOCAL_DB_CONFIG = {
    'dbname': 'postgres',
    'user': 'postgres',
    'password': 'pa$$w0rd',
    'host': 'localhost',
    'port': '5432'
}


# Функция для получения данных из удалённой БД
def fetch_remote_data():
    conn = psycopg2.connect(**REMOTE_DB_CONFIG)
    cur = conn.cursor()

    query_med_name = "SELECT * FROM de.med_name"
    query_med_an_name = "SELECT * FROM de.med_an_name"

    cur.execute(query_med_name)
    rows_med_name = cur.fetchall()
    df_med_name = pd.DataFrame(rows_med_name, columns=[desc[0] for desc in cur.description])

    cur.execute(query_med_an_name)
    rows_med_an_name = cur.fetchall()
    df_med_an_name = pd.DataFrame(rows_med_an_name, columns=[desc[0] for desc in cur.description])

    cur.close()
    conn.close()

    return df_med_name, df_med_an_name


# Функция для создания таблиц в локальной БД
def create_local_tables():
    conn = psycopg2.connect(**LOCAL_DB_CONFIG)
    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE IF NOT EXISTS med_name (
            id SERIAL PRIMARY KEY,
            name TEXT,
            phone TEXT
        )
    """)

    cur.execute("""
        CREATE TABLE IF NOT EXISTS med_an_name (
            id TEXT PRIMARY KEY,
            name TEXT,
            is_simple TEXT,
            min_value FLOAT,
            max_value FLOAT
        )
    """)

    conn.commit()
    cur.close()
    conn.close()


# Функция загрузки данных в локальную БД
def load_to_local_db(df_med_name, df_med_an_name):
    conn = psycopg2.connect(**LOCAL_DB_CONFIG)
    cur = conn.cursor()

    # Очистка таблиц перед загрузкой новых данных
    cur.execute("TRUNCATE TABLE med_name RESTART IDENTITY CASCADE")
    cur.execute("TRUNCATE TABLE med_an_name RESTART IDENTITY CASCADE")

    for _, row in df_med_name.iterrows():
        cur.execute(
            "INSERT INTO med_name (name, phone) VALUES (%s, %s)",
            (row['name'], row['phone'])
        )

    for _, row in df_med_an_name.iterrows():
        cur.execute(
            "INSERT INTO med_an_name (id, name, is_simple, min_value, max_value) VALUES (%s, %s, %s, %s, %s)",
            (row['id'], row['name'], row['is_simple'], row['min_value'], row['max_value'])
        )

    conn.commit()
    cur.close()
    conn.close()


# Функция загрузки данных из Excel в локальную БД
def load_medicine_xlsx():
    df_xlsx = pd.read_excel('medicine.xlsx')

    conn = psycopg2.connect(**LOCAL_DB_CONFIG)
    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE IF NOT EXISTS medicine_data (
            id SERIAL PRIMARY KEY,
            name TEXT,
            category TEXT,
            price FLOAT
        )
    """)

    cur.execute("TRUNCATE TABLE medicine_data RESTART IDENTITY CASCADE")

    for _, row in df_xlsx.iterrows():
        cur.execute(
            "INSERT INTO medicine_data (name, category, price) VALUES (%s, %s, %s)",
            (row['name'], row['category'], row['price'])
        )

    conn.commit()
    cur.close()
    conn.close()

    return df_xlsx


# Функция сохранения обработанных данных
def save_processed_data(df_xlsx):
    processed_file = 'processed_medicine.xlsx'
    df_xlsx.to_excel(processed_file, index=False)
    print(f"Файл сохранён: {processed_file}")


# Основной процесс
def main():
    df_med_name, df_med_an_name = fetch_remote_data()
    create_local_tables()
    load_to_local_db(df_med_name, df_med_an_name)
    df_xlsx = load_medicine_xlsx()
    save_processed_data(df_xlsx)


if __name__ == '__main__':
    main()
