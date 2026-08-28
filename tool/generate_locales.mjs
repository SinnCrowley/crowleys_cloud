import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const arbDir = path.join(root, 'lib/l10n');
const webDir = path.join(root, 'server/web/src/i18n');

const locales = [
  ['zh_Hans', 'zh-CN', '简体中文'],
  ['es', 'es', 'Español'],
  ['ja', 'ja', '日本語'],
  ['pt_BR', 'pt-BR', 'Português (Brasil)'],
  ['de', 'de', 'Deutsch'],
  ['ar', 'ar', 'العربية'],
  ['fr', 'fr', 'Français'],
  ['ko', 'ko', '한국어'],
  ['hi', 'hi', 'हिन्दी'],
  ['it', 'it', 'Italiano'],
  ['tr', 'tr', 'Türkçe'],
  ['id', 'id', 'Bahasa Indonesia'],
  ['vi', 'vi', 'Tiếng Việt'],
  ['bn', 'bn', 'বাংলা'],
  ['fa', 'fa', 'فارسی'],
  ['uk', 'uk', 'Українська'],
  ['pl', 'pl', 'Polski'],
];

const replacements = {
  'zh-CN': { Save: '保存', Cancel: '取消', Delete: '删除', Close: '关闭', Search: '搜索', Upload: '上传', Download: '下载', Share: '分享', Rename: '重命名', Settings: '设置', 'Loading...': '加载中...', Error: '错误', 'No files found.': '未找到文件。' },
  es: { Save: 'Guardar', Cancel: 'Cancelar', Delete: 'Eliminar', Close: 'Cerrar', Search: 'Buscar', Upload: 'Subir', Download: 'Descargar', Share: 'Compartir', Rename: 'Renombrar', Settings: 'Configuración', 'Loading...': 'Cargando...', Error: 'Error', 'No files found.': 'No se encontraron archivos.' },
  ja: { Save: '保存', Cancel: 'キャンセル', Delete: '削除', Close: '閉じる', Search: '検索', Upload: 'アップロード', Download: 'ダウンロード', Share: '共有', Rename: '名前を変更', Settings: '設定', 'Loading...': '読み込み中...', Error: 'エラー', 'No files found.': 'ファイルが見つかりません。' },
  'pt-BR': { Save: 'Salvar', Cancel: 'Cancelar', Delete: 'Excluir', Close: 'Fechar', Search: 'Pesquisar', Upload: 'Enviar', Download: 'Baixar', Share: 'Compartilhar', Rename: 'Renomear', Settings: 'Configurações', 'Loading...': 'Carregando...', Error: 'Erro', 'No files found.': 'Nenhum arquivo encontrado.' },
  de: { Save: 'Speichern', Cancel: 'Abbrechen', Delete: 'Löschen', Close: 'Schließen', Search: 'Suchen', Upload: 'Hochladen', Download: 'Herunterladen', Share: 'Teilen', Rename: 'Umbenennen', Settings: 'Einstellungen', 'Loading...': 'Wird geladen...', Error: 'Fehler', 'No files found.': 'Keine Dateien gefunden.' },
  ar: { Save: 'حفظ', Cancel: 'إلغاء', Delete: 'حذف', Close: 'إغلاق', Search: 'بحث', Upload: 'رفع', Download: 'تنزيل', Share: 'مشاركة', Rename: 'إعادة تسمية', Settings: 'الإعدادات', 'Loading...': 'جارٍ التحميل...', Error: 'خطأ', 'No files found.': 'لم يتم العثور على ملفات.' },
  fr: { Save: 'Enregistrer', Cancel: 'Annuler', Delete: 'Supprimer', Close: 'Fermer', Search: 'Rechercher', Upload: 'Importer', Download: 'Télécharger', Share: 'Partager', Rename: 'Renommer', Settings: 'Paramètres', 'Loading...': 'Chargement...', Error: 'Erreur', 'No files found.': 'Aucun fichier trouvé.' },
  ko: { Save: '저장', Cancel: '취소', Delete: '삭제', Close: '닫기', Search: '검색', Upload: '업로드', Download: '다운로드', Share: '공유', Rename: '이름 변경', Settings: '설정', 'Loading...': '로드 중...', Error: '오류', 'No files found.': '파일을 찾을 수 없습니다.' },
  hi: { Save: 'सहेजें', Cancel: 'रद्द करें', Delete: 'हटाएं', Close: 'बंद करें', Search: 'खोजें', Upload: 'अपलोड', Download: 'डाउनलोड', Share: 'साझा करें', Rename: 'नाम बदलें', Settings: 'सेटिंग्स', 'Loading...': 'लोड हो रहा है...', Error: 'त्रुटि', 'No files found.': 'कोई फ़ाइल नहीं मिली।' },
  it: { Save: 'Salva', Cancel: 'Annulla', Delete: 'Elimina', Close: 'Chiudi', Search: 'Cerca', Upload: 'Carica', Download: 'Scarica', Share: 'Condividi', Rename: 'Rinomina', Settings: 'Impostazioni', 'Loading...': 'Caricamento...', Error: 'Errore', 'No files found.': 'Nessun file trovato.' },
  tr: { Save: 'Kaydet', Cancel: 'İptal', Delete: 'Sil', Close: 'Kapat', Search: 'Ara', Upload: 'Yükle', Download: 'İndir', Share: 'Paylaş', Rename: 'Yeniden adlandır', Settings: 'Ayarlar', 'Loading...': 'Yükleniyor...', Error: 'Hata', 'No files found.': 'Dosya bulunamadı.' },
  id: { Save: 'Simpan', Cancel: 'Batal', Delete: 'Hapus', Close: 'Tutup', Search: 'Cari', Upload: 'Unggah', Download: 'Unduh', Share: 'Bagikan', Rename: 'Ganti nama', Settings: 'Pengaturan', 'Loading...': 'Memuat...', Error: 'Kesalahan', 'No files found.': 'Tidak ada file.' },
  vi: { Save: 'Lưu', Cancel: 'Hủy', Delete: 'Xóa', Close: 'Đóng', Search: 'Tìm kiếm', Upload: 'Tải lên', Download: 'Tải xuống', Share: 'Chia sẻ', Rename: 'Đổi tên', Settings: 'Cài đặt', 'Loading...': 'Đang tải...', Error: 'Lỗi', 'No files found.': 'Không tìm thấy tệp.' },
  bn: { Save: 'সংরক্ষণ', Cancel: 'বাতিল', Delete: 'মুছুন', Close: 'বন্ধ করুন', Search: 'অনুসন্ধান', Upload: 'আপলোড', Download: 'ডাউনলোড', Share: 'শেয়ার', Rename: 'নাম পরিবর্তন', Settings: 'সেটিংস', 'Loading...': 'লোড হচ্ছে...', Error: 'ত্রুটি', 'No files found.': 'কোনো ফাইল পাওয়া যায়নি।' },
  fa: { Save: 'ذخیره', Cancel: 'لغو', Delete: 'حذف', Close: 'بستن', Search: 'جستجو', Upload: 'بارگذاری', Download: 'دانلود', Share: 'اشتراک‌گذاری', Rename: 'تغییر نام', Settings: 'تنظیمات', 'Loading...': 'در حال بارگذاری...', Error: 'خطا', 'No files found.': 'فایلی پیدا نشد.' },
  uk: { Save: 'Зберегти', Cancel: 'Скасувати', Delete: 'Видалити', Close: 'Закрити', Search: 'Пошук', Upload: 'Завантажити', Download: 'Завантажити', Share: 'Поділитися', Rename: 'Перейменувати', Settings: 'Налаштування', 'Loading...': 'Завантаження...', Error: 'Помилка', 'No files found.': 'Файлів не знайдено.' },
  pl: { Save: 'Zapisz', Cancel: 'Anuluj', Delete: 'Usuń', Close: 'Zamknij', Search: 'Szukaj', Upload: 'Prześlij', Download: 'Pobierz', Share: 'Udostępnij', Rename: 'Zmień nazwę', Settings: 'Ustawienia', 'Loading...': 'Ładowanie...', Error: 'Błąd', 'No files found.': 'Nie znaleziono plików.' },
};

function translate(value, locale) {
  if (typeof value === 'string') return replacements[locale]?.[value] ?? value;
  if (Array.isArray(value)) return value.map((item) => translate(item, locale));
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, translate(v, locale)]));
  return value;
}

const enArb = JSON.parse(fs.readFileSync(path.join(arbDir, 'app_en.arb'), 'utf8'));
const enWeb = JSON.parse(fs.readFileSync(path.join(webDir, 'en.json'), 'utf8'));
const ruWeb = JSON.parse(fs.readFileSync(path.join(webDir, 'ru.json'), 'utf8'));
const languageLabels = Object.fromEntries(locales.map(([, locale, label]) => [locale, label]));
for (const dictionary of [enWeb, ruWeb]) {
  for (const [locale, label] of Object.entries(languageLabels)) dictionary.settings[`language_${locale}`] = label;
}
fs.writeFileSync(path.join(webDir, 'en.json'), `${JSON.stringify(enWeb, null, 2)}\n`);
fs.writeFileSync(path.join(webDir, 'ru.json'), `${JSON.stringify(ruWeb, null, 2)}\n`);
for (const [arbLocale, webLocale, label] of locales) {
  const arb = translate(enArb, webLocale);
  arb['@@locale'] = arbLocale;
  fs.writeFileSync(path.join(arbDir, `app_${arbLocale}.arb`), `${JSON.stringify(arb, null, 2)}\n`);
  if (arbLocale === 'pt_BR') {
    const ptFallback = { ...arb, '@@locale': 'pt' };
    fs.writeFileSync(path.join(arbDir, 'app_pt.arb'), `${JSON.stringify(ptFallback, null, 2)}\n`);
  }
  if (arbLocale === 'zh_Hans') {
    const zhFallback = { ...arb, '@@locale': 'zh' };
    fs.writeFileSync(path.join(arbDir, 'app_zh.arb'), `${JSON.stringify(zhFallback, null, 2)}\n`);
  }

  const web = translate(enWeb, webLocale);
  web.settings.language = 'Language';
  web.settings.language_desc = 'Select application interface language.';
  web.settings.language_auto = 'Auto (System)';
  web.settings.language_en = 'English';
  web.settings.language_ru = 'Русский';
  fs.writeFileSync(path.join(webDir, `${webLocale}.json`), `${JSON.stringify(web, null, 2)}\n`);
}

// Flutter gen-l10n also emits base fallbacks for script/country locales.
// Keep matching web dictionaries so both clients expose the same catalog.
for (const [base, regional] of [['pt', 'pt-BR'], ['zh', 'zh-CN']]) {
  const regionalDictionary = JSON.parse(fs.readFileSync(path.join(webDir, `${regional}.json`), 'utf8'));
  fs.writeFileSync(path.join(webDir, `${base}.json`), `${JSON.stringify(regionalDictionary, null, 2)}\n`);
}
