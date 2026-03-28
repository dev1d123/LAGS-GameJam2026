# 🌍 Guía de Traducción Dinámica (Método Componentes)

Sigue estos 3 simples pasos para traducir **cualquier** elemento de tu interfaz (`Label`, `Button`, `RichTextLabel`, etc.).

## 1. Crea o Identifica tu Archivo JSON
Ve a `data/localization/` y crea el archivo [.json](file:///c:/Users/DrN/Documents/LAGS2026/LAGS-GameJam2026/lags-2026/data/localization/main_menu.json) que agrupará tus textos (por ejemplo `gameplay.json`).
Dentro, define tus claves y los idiomas soportados:
```json
{
  "inventory_title": {
	"es": "INVENTARIO",
	"en": "INVENTORY",
	"pt": "INVENTÁRIO"
  }
}
```

## 2. Para Botones Nativos ([diegetic_button.gd](file:///c:/Users/DrN/Documents/LAGS2026/LAGS-GameJam2026/lags-2026/ui/components/diegetic_button.gd) o [button_1.gd](file:///c:/Users/DrN/Documents/LAGS2026/LAGS-GameJam2026/lags-2026/ui/screens/button_1.gd))
Nuestros botones premium ya traen el traductor incrustado. 
1. Haz clic en tu botón en la escena.
2. Mira el **Inspector derecho**, busca la sección **"Textos y Traducción"**.
3. Rellena:
   - `Translation Category`: El nombre de tu archivo (Ej: `gameplay`)
   - `Translation Key`: La clave de tu texto (Ej: `inventory_title`)

## 3. Para cualquier otro texto (`Label`, `RichTextLabel`, etc.)
"No solamente un Label puede tener texto". Por eso el nuevo componente es universal.
1. Selecciona tu nodo `Label` (¡o cualquier nodo que muestre texto!) en la escena.
2. En el panel Inspector (derecha), baja hasta el final y busca donde dice **Script** o simplemente haz clic derecho sobre el nodo -> **Attach Script** (Añadir Script).
3. Carga nuestro script: `res://ui/components/localized_text.gd`.
4. ¡Magia! En la parte superior del inspector aparecerá la sección **"Textos y Traducción"**.
5. Rellena el `Category` y el `Key` según tu JSON.

---
