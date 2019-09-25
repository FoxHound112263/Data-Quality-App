# -*- coding: utf-8 -*-
"""
Created on Tue Sep 10 11:13:15 2019

@author: cmayorquin
"""
import pandas as pd
import numpy as np

############## EVALUAR TIPOS DE COLUMNAS
########## tipos de las columnas
# pasar columnas a numéricos, si posibl

def tipo_col(base):
    base_numerizada=base.apply(lambda x:x.astype(float,errors="ignore"),axis=0)
    tipos_columnas=base_numerizada.dtypes
    return(tipos_columnas)
    #tipos_columnas=tipos_columnas.rename(columns={0:"Tipo"})

########## valores únicos en cada columna
# sin missing values
def val_unicos_col(base):
    unicos_columnas=base.apply(lambda x:len(x.value_counts()),axis=0)
    return(unicos_columnas)
    #unicos_columnas=unicos_columnas.rename(columns={0:"Valores únicos"})
    
# con missing values
def val_unicos_col_missing(base):
    unicos_columnas=base.apply(lambda x:len(x.value_counts(dropna=False)),axis=0)
    return(unicos_columnas)

########## COMPLETITUD. Missing 
def missing_porc(base):
    missing_columnas=pd.isnull(base).sum()/len(base)
    return(missing_columnas)
    #missing_columnas=missing_columnas.rename(columns={0:"Porcentaje de valores faltantes"})
    
########## VERACIDAD. Porcentaje y número de filas y columnas no únicas
def filas_no_unic_porc(base):
    no_unic_filas=base.duplicated(keep=False)
    porc=no_unic_filas[no_unic_filas==True].shape[0]/base.shape[0]
    return(porc)
def col_no_unic_porc(base):
    no_unic_columnas=base.T.duplicated(keep=False)
    porc=no_unic_columnas[no_unic_columnas==True].shape[0]/base.shape[1]
    return(porc)
def filas_no_unic_num(base):
    no_unic_filas=base.duplicated(keep=False)
    num=no_unic_filas[no_unic_filas==True].shape[0]
    return(num)
def col_no_unic_num(base):
    no_unic_columnas=base.T.duplicated(keep=False)
    num=no_unic_columnas[no_unic_columnas==True].shape[0]
    return(num)

########## MATCHING DE COLUMNAS Y FILAS NO ÚNICAS
########## matching de columnas duplicadas
def duplicados_col(base):
    col_dupli=base.T.duplicated(keep=False)
    col_dupli=col_dupli[col_dupli==True]
    if col_dupli.sum()==0:
        return("No hay columnas duplicadas")
    lista_duplicados=[]
    for s in col_dupli.index:
        for ss in col_dupli.index:
            if base[s].equals(base[ss]) and s!=ss:
                lista_duplicados.append([s,ss])
    dic={}
    for s in col_dupli.index:
        dic[s]=[]
    for s in col_dupli.index:
        for i in range(len(lista_duplicados)):
            if s in lista_duplicados[i]:
                dic[s].append(lista_duplicados[i])
    for s in dic:
        lista=[q for l in dic[s] for q in l]
        dic[s]=list(set(lista))
    
    lista_listas=[q for q in dic.values()]
    df=pd.DataFrame(lista_listas).drop_duplicates().reset_index(drop=True)
    
    return(df)

########## matching de filas duplicadas
def duplicados_fila(base):
    fila_dupli=base.duplicated(keep=False)
    fila_dupli=fila_dupli[fila_dupli==True]
    if fila_dupli.sum()==0:
        return("No hay filas duplicadas")
    lista_duplicados=[]
    for s in fila_dupli.index:
        for ss in fila_dupli.index:
            if base.iloc[s].equals(base.iloc[ss]) and s!=ss:
                lista_duplicados.append([s,ss])
    lista_duplicados=sorted(lista_duplicados)
    dic={}
    for s in fila_dupli.index:
        dic[s]=[]
    for s in fila_dupli.index:
        for i in range(len(lista_duplicados)):
            if s in lista_duplicados[i]:
                dic[s].append(lista_duplicados[i])
    for s in dic:
        lista=[q for l in dic[s] for q in l]
        dic[s]=list(set(lista))
    
    lista_listas=[sorted(q) for q in dic.values()]
    
    for i in range(len(lista_listas)): 
        for ii in range(len(lista_listas[i])):
            lista_listas[i][ii]=str(lista_listas[i][ii])

    df=pd.DataFrame(lista_listas).drop_duplicates().reset_index(drop=True)
    
    return(df)

########## CONSISTENCIA. Porcentaje de outliers
def outliers_porc(base):
    base_numerizada=base.apply(lambda x:x.astype(float,errors="ignore"),axis=0)
    col_tipos=tipo_col(base_numerizada)
    col_num=col_tipos[col_tipos=="float64"].index
    base_num=base_numerizada[col_num]
    
    percentiles_25=base_num.apply(lambda x:np.nanpercentile(x,25),axis=0)
    percentiles_75=base_num.apply(lambda x:np.nanpercentile(x,75),axis=0)
    
    iqr=percentiles_75-percentiles_25
    iqr_upper=percentiles_75+iqr*1.5
    iqr_lower=percentiles_25-iqr*1.5

    dic_outliers={}
    for i in range(0,len(iqr)):
        dic_outliers[base_num.columns[i]]=(base_num.iloc[:,i]>iqr_upper[i])|(base_num.iloc[:,i]<iqr_lower[i])
    
    base_outliers=pd.DataFrame(dic_outliers)
    base_outliers_porc=base_outliers.sum()/base_outliers.shape[0]

    return(base_outliers_porc)        
    
############## describe de columnas
def descripcion(base):
    base_numerizada=base.apply(lambda x:x.astype(float,errors="ignore"),axis=0)
    col_tipos=tipo_col(base_numerizada)
    col_num=col_tipos[col_tipos=="float64"].index
    base_num=base_numerizada[col_num] 
    
    base_descripcion=base_num.describe().T
    base_descripcion["count"]=pd.isnull(base_num).sum()/len(base_num)
    base_descripcion["outliers"]=outliers_porc(base)
    
    return(base_descripcion)

############### tabla de valores únicos para cada variable de texto
def valor_unico_texto(base):
    col_texto=tipo_col(base)
    col_texto=col_texto[col_texto=="object"]
       
    lista_counts=[]
    for s in col_texto.index:
        counts=base[s].value_counts()
        
        lista=counts[0:10]
        resto=counts[10:len(counts)].sum()
        miss=pd.isnull(base[s]).sum()
        
        lista["Demás categorías"]=resto
        lista["Datos faltantes"]=miss
        lista=lista.to_frame()
        lista["Columna"]=s
        lista["Porcentaje del total de filas"]=lista[s]/len(base)
    
        resto=lista.iloc[:,0].loc["Demás categorías"]
        if resto==0:
            lista=lista.drop("Demás categorías",axis=0)

        lista=lista.reset_index()
        
        s=lista.columns.tolist()[1]
        colis=["Columna","index",s,"Porcentaje del total de filas"]
        lista=lista[colis]
        lista_cols=lista.columns.tolist()
        lista=lista.rename(columns={"index":"Valor",lista_cols[2]:"Frecuencia"})
        lista_counts.append(lista)
    df_counts=pd.concat(lista_counts,axis=0)
    return(df_counts)
      
########## tabla de resumen pequeña
def tabla_resumen(base):
    datos=["" for q in range(8)]
    nombres=["Número de filas","Número de columnas","Columnas numéricas","Columnas de texto","Número de filas duplicadas","Número de columnas duplicadas","Columnas con más de la mitad de datos faltantes","Columnas con más del 10% de datos como extremos"]
    
    col_tipos=tipo_col(base)
    col_texto=col_tipos[col_tipos=="object"]
    col_num=col_tipos[col_tipos=="float64"]

    col_missing=missing_porc(base)
    col_missing_50=col_missing[col_missing>0.5]

    col_porc=outliers_porc(base)
    col_porc_10=col_porc[col_porc>0.1]

    datos[0]=base.shape[0]
    datos[1]=base.shape[1]
    datos[2]=len(col_num)
    datos[3]=len(col_texto)
    datos[4]=filas_no_unic_num(base)
    datos[5]=col_no_unic_num(base)
    datos[6]=len(col_missing_50)
    datos[7]=len(col_porc_10)

    tabla_resumen=pd.Series(data=datos,index=nombres)
    return(tabla_resumen)

########### EXTRAER DATOS DE LA BASE ANALIZADA
def info_base_tabla(api_id,tabla):
    conjuntos=tabla[tabla["externos"]=="Conjunto de Datos"]
    info_base=conjuntos.loc[tabla.loc[:,"api_id"]==api_id]
    return(info_base)