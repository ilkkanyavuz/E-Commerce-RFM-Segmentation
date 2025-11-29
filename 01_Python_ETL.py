import pandas as pd
from sqlalchemy import create_engine
from urllib.parse import quote_plus

SERVER_NAME = 'DESKTOP-LOK66G1\\RFM_INSTANCE'
DATABASE_NAME = 'ECOM_DB'
TABLE_NAME = 'OnlineRetail_cleaned'
FILE_NAME = 'OnlineRetail_YENI.csv'

df=pd.read_csv('OnlineRetail_YENI.csv',encoding='latin1')
pd.set_option('display.max_columns',None)
pd.set_option('display.width',1000)
print(df.info())
print(df.describe(include='all'))
print(df.isnull().sum())

#TASK SERIES 2: STANDARDIZATIONdf.columns=df.columns.str.lower()
remapping={'invoiceno':'invoice_no','stockcode':'stock_code','invoicedate':'invoice_date','unitprice':'unit_price', 'customerid':'customer_id'}
df=df.rename(columns=remapping)

#Task 2.2: Critical Missing Value Cleaning
df.dropna(subset=['customer_id'], inplace=True)
df['customer_id']=df['customer_id'].astype('object')
df['invoice_date']=pd.to_datetime(df['invoice_date'])

#TASK SERIES 3: Outlier Management
df=df[df['quantity']>0]
df=df[df['unit_price']>0]
Q1_qu=df['quantity'].quantile(0.25)
Q3_qu=df['quantity'].quantile(0.75)
IQR=Q3_qu-Q1_qu
upper_bound1=Q3_qu+1.5 *IQR
df.loc[df['quantity']>upper_bound1,'quantity']=upper_bound1

Q1_price=df['unit_price'].quantile(0.25)
Q3_price=df['unit_price'].quantile(0.75)
IQR=Q3_price-Q1_price
upper_bound2=Q3_price+1.5 *IQR
df.loc[df['unit_price']>upper_bound2,'unit_price']=upper_bound2

#TASK SERIES 3: Outlier Management
df['total_price']=df['quantity']*df['unit_price']

connection_string = (
    f"DRIVER={{ODBC Driver 18 for SQL Server}};"
    f"SERVER={SERVER_NAME};"
    f"DATABASE={DATABASE_NAME};"
    f"Trusted_Connection=yes;"
    f"Encrypt=yes;"
    f"TrustServerCertificate=yes;"
)
quoted_conn_string = quote_plus(connection_string)
engine = create_engine(f'mssql+pyodbc:///?odbc_connect={quoted_conn_string}')
try:
    df.to_sql(
        name=TABLE_NAME,
        con=engine,
        if_exists='replace',
        index=False
    )
    print(f"✅ Successful! {len(df)} rows of cleaned and modeled data have been loaded into the '{TABLE_NAME}' table")

except Exception as e:
    print(f"❌ A critical error occurred while loading the data: {e}")