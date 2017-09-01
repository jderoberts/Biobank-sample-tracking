import sqlite3
from sqlite3 import Error

def db_connect(db_file):
    try:
        conn = sqlite3.connect(db_file)
        return conn
    except Error as e:
        print(e)

def create_table(conn, statement):
    try:
        c = conn.cursor()
        c.execute(statement)
    except Error as e:
        print(e)

def insert_data(conn, statement, data):
    c = conn.cursor()
    c.execute(statement, data)
    return c.lastrowid

def fetch_csv_data(filename):
    data = []
    with open(filename,'r') as infile:
        for line in infile:
          vals = line.strip().split(',')
          data.append(tuple(vals))
    return data

def main():
    db = "samples.db"
    sample_pt_tbl = """ CREATE TABLE IF NOT EXISTS sample_patient (
                       sample_id text PRIMARY KEY,
                       upin text NOT NULL,
                       alias text
                       ); """
    sample_data_tbl = """ CREATE TABLE IF NOT EXISTS sample_data (
                       id integer PRIMARY KEY,
                       sample_id text NOT NULL,
                       diagnosis text,
                       consent text,
                       trial_number text,
                       sample_date text,
                       sample_source text,
                       sample_type text,
                       FOREIGN KEY (sample_id) REFERENCES sample_patient (sample_id)
                       ); """
    cellular_products_tbl =  """ CREATE TABLE IF NOT EXISTS cellular_products (
                       id integer PRIMARY KEY,
                       sample_id text NOT NULL,
                       product_barcode text UNIQUE NOT NULL,
                       cell_type text,
                       product_type text,
                       location_box text,
                       location_well text,
                       available integer,
                       FOREIGN KEY (sample_id) REFERENCES sample_patient (sample_id)
                       ); """
    molecular_products_tbl =  """ CREATE TABLE IF NOT EXISTS molecular_products (
                       id integer PRIMARY KEY,
                       sample_id text NOT NULL,
                       parent_barcode text NOT NULL,
                       product_barcode text UNIQUE NOT NULL,
                       cell_type text,
                       product_type text,
                       location_box text,
                       location_well text,
                       available integer,
                       FOREIGN KEY (sample_id) REFERENCES sample_patient (sample_id),
                       FOREIGN KEY (parent_barcode) REFERENCES cellular_products (product_barcode)
                       ); """
    sample_pt_sql = " INSERT INTO sample_patient(sample_id,upin,alias) VALUES(?,?,?) "
    sample_data_sql = " INSERT INTO sample_data(sample_id, diagnosis, consent, trial_number, sample_date, sample_source, sample_type) VALUES(?,?,?,?,?,?,?) "
    cellular_prods_sql = " INSERT INTO cellular_products(sample_id, product_barcode, cell_type, product_type, location_box, location_well, available) VALUES(?,?,?,?,?,?,?) "
    molecular_prods_sql = " INSERT INTO molecular_products(sample_id, parent_barcode, product_barcode, cell_type, product_type, location_box, location_well, available) VALUES(?,?,?,?,?,?,?,?) "

    sample_pt_recs = fetch_csv_data('sample_patient.csv')
    sample_data_recs = fetch_csv_data('sample_data.csv')
    cellular_prods_recs = fetch_csv_data('cellular_products.csv')
    molecular_prods_recs = fetch_csv_data('molecular_products.csv')

    conn = db_connect(db)
    with conn:
        create_table(conn, sample_pt_tbl)
        create_table(conn, sample_data_tbl)
        create_table(conn, cellular_products_tbl)
        create_table(conn, molecular_products_tbl)
        for record in sample_pt_recs:
            insert_data(conn,sample_pt_sql,record)
        for record in sample_data_recs:
            insert_data(conn,sample_data_sql,record)
        for record in cellular_prods_recs:
            insert_data(conn,cellular_prods_sql,record)
        for record in molecular_prods_recs:
            insert_data(conn,molecular_prods_sql,record)

if __name__ == '__main__':
    main()
