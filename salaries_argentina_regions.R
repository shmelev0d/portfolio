library(tidyverse)
library(sf)
library(zoo)
library(readr)


# reading data

df_letra_promedio <- readr::read_csv("https://cdn.produccion.gob.ar/cdn-cep/datos-por-departamento/salarios/w_mean_depto_total_letra.csv")
df_clae2 <- readr::read_csv("https://cdn.produccion.gob.ar/cdn-cep/datos-por-departamento/diccionario_clae2.csv")

glimpse(df_letra_promedio)


geodata <- read_sf("data/departamentos_arg.geojson")
ggplot(geodata) + 
  geom_sf(aes(fill = provincia))

# checking classes

class(df_letra_promedio$codigo_departamento_indec)
class(geodata$codigo_departamento_indec)


# data exploration shows the impact of outliers
mean(df_letra_promedio$w_mean)
median(df_letra_promedio$w_mean)
mad(df_letra_promedio$w_mean)
sd(df_letra_promedio$w_mean)
mean(df_letra_promedio$w_mean, trim = 0.35)
IQR(df_letra_promedio$w_mean)


# data preparation

# prepare the dictionary

df_clae2 <- df_clae2 %>%
  select(letra, letra_desc) %>%
  distinct() %>%
  mutate(letra = ifelse(is.na(letra), "Z", letra))
df_clae2

# join dataframe with the dictionary

df_letra_promedio <- df_letra_promedio %>%
  left_join(df_clae2, by = "letra") %>%
  mutate(year = year(fecha)) %>%
  select(year, codigo_departamento_indec, id_provincia_indec, letra, letra_desc, w_mean) %>%
  filter(id_provincia_indec != 2)

df_letra_promedio

# counting NAs (-99)

number_NAs <- df_letra_promedio %>%
  group_by(letra_desc) %>%
  summarize(total_cases = n(), 
            NAs_by_sectors = sum(w_mean == -99), 
            NAs_prct = sum(w_mean== -99) / n() * 100)

number_NAs

ggplot(number_NAs, aes(x = letra_desc)) +
  geom_col(aes(y = total_cases), fill = "skyblue", alpha = 0.7) +
  geom_col(aes(y = NAs_by_sectors), fill = "red", alpha = 0.5) + 
  coord_flip()

# turning -99 records to NAs

df_letra_promedio$w_mean[df_letra_promedio$w_mean == -99] <- NA


## substituting NAs with median salaries by the sector
# creating a dataframe of median salaries
median_salaries <- df_letra_promedio %>%
  group_by(letra_desc) %>%
  summarise(median_salary = median(w_mean, na.rm = TRUE))
median_salaries

df_letra_promedio <- df_letra_promedio %>%
  left_join(median_salaries, by = "letra_desc") %>%
  mutate(w_mean = ifelse(is.na(w_mean), median_salary, w_mean)) %>%  # if w_mean is na. change to median_salary
  select(-median_salary)

# checking result
mean(df_letra_promedio$w_mean)
median(df_letra_promedio$w_mean)


# outliers

quantile(df_letra_promedio$w_mean, p = c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1))

max(df_letra_promedio$w_mean)
min(df_letra_promedio$w_mean)
mad(df_letra_promedio$w_mean)
sd(df_letra_promedio$w_mean)

ggplot(df_letra_promew_meanggplot(df_letra_promedio, aes(letra_desc, w_mean)) + 
  geom_boxplot() + 
  coord_flip()

# preparing geodata
# in geodata the column codigo_departamento_indec was a character, so I had to turn it into numeric

geodata <- geodata %>%
  filter(codpcia != "02") %>%  # delete CABA
  mutate(codigo_departamento_indec = as.numeric(codigo_departamento_indec)) %>% 
  select(codpcia, departamen, provincia, codigo_departamento_indec, geometry)

geodata
  
ggplot(geodata) + 
  geom_sf(aes(fill = provincia))


# Tarea nro 1

# group by departamentos usando codigo de departamento

df_letra_promedio_dep <- df_letra_promedio %>%
  group_by(codigo_departamento_indec) %>%
  summarise(promedio = mean(w_mean, na.rm = TRUE))

df_letra_promedio_dep

# join data y geodata

geodata_salary <- geodata %>%
  full_join(df_letra_promedio_dep, by = c("codigo_departamento_indec"))

# el plot de salarios promedios en todo el pais

geodata_salary_plot <- ggplot(geodata_salary) + 
  geom_sf(aes(fill = promedio)) + 
  scale_fill_viridis_c(na.value = "grey60", name = "Salario Promedio") +
  labs(title = "Salarios promedios por departamento", subtitle = "años 2014 - 2023", 
       caption = "Segun Dirección Nacional de Estudios para la Producción.") + 
  theme_minimal() 

geodata_salary_plot

ggsave('images/geodata_salary_plot.png', width = 8, height = 5)


# calculamos el tercer cuartil para indicar los departamentos con salarios mayores

umbral <- quantile(geodata_salary$promedio, 0.75, na.rm = TRUE)
print(umbral)

# creamos nueva variable categorical para indica los salarios mayores

geodata_salary <- geodata_salary %>%
  mutate(salario_alto = ifelse(promedio > umbral, "Alto", "Bajo"))


# un plot de regiones con salarios mayores

geodata_salary_plot2 <- ggplot(geodata_salary) + 
  geom_sf(aes(fill = salario_alto), color = "white") + 
  scale_fill_manual(values = c("Alto" = "red", "Bajo" = "steelblue"), name = "Monto del salario") +
  labs(title = "Departamentos con salarios mayores(Percentil 75)", subtitle = "años 2014 - 2023", 
       caption = "Segun Dirección Nacional de Estudios para la Producción.") + 
  theme_minimal()

geodata_salary_plot2

ggsave('images/geodata_salary_plot2.png', width = 8, height = 5)

# -----------------------------------------------------

# Tarea 2

promedio_sectores <- df_letra_promedio %>%
  group_by(letra_desc) %>%
  summarize(promedio = mean(w_mean)) %>%
  arrange (promedio) 


salarios_bajos <- promedio_sectores %>%
  head(5)

salarios_bajos_plot <- ggplot (salarios_bajos, aes(x= reorder(letra_desc, promedio), y = promedio)) +
  geom_col(width = 0.5, fill = "steelblue") +
  theme_minimal() +
  theme( 
    plot.title = element_text(size = 14, face = "bold"),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 10),
    legend.background = element_rect(fill = "lightgray", color = "black"),
    axis.text = element_text (hjust = 0.5, size = 6))+
  labs(title = "Sectores de actividad con salarios más bajos",
       x= "Sectores de actividad", y = "Promedio salarial",
       caption = "Fuente: Datos Ministerio de Desarrollo Productivo")+
  scale_x_discrete(labels = c(
    "SERVICIOS DE ALOJAMIENTO Y SERVICIOS DE COMIDA" = "Serv. Alojamiento y comida",
    "ACTIVIDADES ADMINISTRATIVAS Y SERVICIOS DE APOYO" = "Act. Administrativas",
    "SERVICIOS INMOBILIARIOS" = "Serv. Inmobiliarios",
    "ENSEÑANZA" = "Enseñanza",
    "SERVICIOS  ARTÍSTICOS, CULTURALES, DEPORTIVOS  Y DE ESPARCIMIENTO" = "Serv. Culturales")) + 
  expand_limits(y = max(salarios_bajos$promedio) * 1.1)

salarios_bajos_plot

ggsave('images/salarios_bajos_plot.png', width = 8, height = 5)

#---------------------------------------------------------

# Tarea 3

# dataframe de salarios promedios

df_año_promedio <- df_letra_promedio %>%
  group_by(year) %>%
  summarise(promedio = mean(w_mean))

df_año_promedio$promedio <- round(df_año_promedio$promedio, 0)


# plot de cambio del salario en total 2014-2023

salario_promedio_plot <- ggplot(df_año_promedio, aes(x = year, y = promedio)) + 
  geom_line(color = "steelblue") +
  geom_point(shape = 21, fill = "steelblue", size = 3) +  
  geom_text(aes(label = promedio), vjust = -1, hjust = 0.5, color = "black") +  
  theme_minimal() +
  labs(title = "Salario Promedio por un Año",
       x = "Año", 
       y = "Salario Promedio")

salario_promedio_plot

ggsave('images/salario_promedio_plot.png', width = 8, height = 5)
# elegimos los 4 sectores: ensenanza, mineria, transporte, construccion

df_cuatro_sectores <- df_letra_promedio %>%
  filter(letra %in% c("F", "P", "H", "B")) %>%
  left_join(df_año_promedio, by = "year") %>%
  mutate(promedio_prct = w_mean)

# conatamos los promedios por el año

df_cuatro_sectores_agg <- df_cuatro_sectores %>%
  group_by(year, letra_desc) %>%  
  summarize(promedio = mean(promedio_prct, na.rm = TRUE)) %>% 
  mutate(ranking = row_number())
df_cuatro_sectores_agg

color_sectores <- c("ENSEÑANZA" = "darkorange", "EXPLOTACION DE MINAS Y CANTERAS" = "red", 
                    "CONSTRUCCIÓN" = "lightblue", "SERVICIO DE TRANSPORTE Y ALMACENAMIENTO" = "green")

df_cuatro_sectores_agg$promedio <- round(df_cuatro_sectores_agg$promedio, 0)


# plot de 4 sectores en relacion a salario promedio nacional
cuatro_sectores_plot <- ggplot(df_cuatro_sectores_agg, aes(x = year, y = promedio, color = letra_desc)) + 
  geom_line() + 
  #geom_text(aes(label = round(promedio, 2)), vjust = -1, hjust = 0.5, color = "black") +  
  geom_point(shape = 21, size = 3) +
  scale_color_manual(values = color_sectores) +  # Используйте scale_color_manual
  theme_minimal() +
  labs(title = "Promedio Salarial por Año",
       x = "Año", 
       y = "Salario Promedio (% de Salario Promedio Nacional)") +
  geom_line(data = df_año_promedio, aes(x = year, y = promedio), color = "red", linetype = "dashed", size = 1) +
  geom_point(data = df_año_promedio, aes(x = year, y = promedio), color = "red", shape = 19) + 
  scale_y_log10()
cuatro_sectores_plot

ggsave('images/cuatro_sectores_plot.png', width = 8, height = 5)

# time transition de cuatro sectores

library(gganimate)

df_cuatro_sectores_agg$year <- as.integer(df_cuatro_sectores_agg$year)

cuatro_sectores_plot <- ggplot(df_cuatro_sectores_agg, aes(x = promedio, y = factor(ranking), fill = letra_desc)) + 
  geom_col() + 
  geom_text(aes(label = letra_desc), size = 3) + 
  scale_fill_manual(values = color_sectores) + 
  theme_minimal() + 
  theme(plot.title = element_text(size = 16, face = "bold")) + 
  labs(title = "Cambio del salario promedio por cuatro sectores en relacion al salario promedio nacional",
       subtitle = "Año: {frame_time}", y = NULL, x = "Salario promedio nacional, %") +
  transition_time(year) +  
  ease_aes('linear')

cuatro_sect_animation <- animate(cuatro_sectores_plot, width = 800, height = 500, 
                                 renderer = gifski_renderer(), fps = 10)

cuatro_sect_animation


anim_save("images/4_sectores.gif", cuatro_sect_animation)
