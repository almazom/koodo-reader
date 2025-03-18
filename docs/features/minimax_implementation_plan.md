# Minimax Chapter Summarization - Имплементационный план

## Фазы разработки

### Фаза 1: Базовая архитектура (3-5 дней)

#### День 1: Настройка окружения и планирование
- [x] Создание ветки `feature/minimax-chapter-summarization`
- [x] Документирование общего плана в `docs/features/minimax_chapter_summarization.md`
- [x] Создание документа промптов на русском `docs/features/minimax_default_prompts_ru.md`
- [x] Определение структуры базы данных SQLite
- [ ] Настройка тестовых ключей API для разработки

#### День 2: Базовые сервисы
- [ ] Разработка структуры LLM сервиса
  - [ ] Создание интерфейса `LLMProvider`
  - [ ] Реализация `MinimaxProvider`
  - [ ] Реализация `LLMServiceManager` с обработкой ошибок
- [ ] Создание утилиты для извлечения текста главы
  - [ ] Использование существующей структуры `htmlBook`
  - [ ] Реализация метода извлечения текста главы

#### День 3: Хранение данных
- [ ] Реализация сервиса управления промптами
  - [ ] Загрузка промптов по умолчанию
  - [ ] Загрузка пользовательских промптов
  - [ ] Редактирование промптов
- [ ] Создание сервиса хранения суммаризаций
  - [ ] Настройка SQLite базы данных
  - [ ] Реализация CRUD операций для суммаризаций

### Фаза 2: UI интеграция (2-3 дня)

#### День 4: Компоненты UI
- [ ] Модификация плавающей кнопки AI
  - [ ] Добавление меню опций при нажатии
  - [ ] Добавление опции суммаризации главы
- [ ] Создание компонента отображения суммаризации
  - [ ] Дизайн модального окна или панели
  - [ ] Реализация индикаторов загрузки

#### День 5: Интеграция UI и сервисов
- [ ] Связывание UI с LLM сервисом
  - [ ] Обработка событий нажатия на опцию суммаризации
  - [ ] Отображение процесса генерации
  - [ ] Обработка ошибок и вывод понятных сообщений
- [ ] Интеграция с системой хранения
  - [ ] Проверка наличия кэшированных суммаризаций
  - [ ] Отображение времени создания суммаризации

### Фаза 3: Настройки и оптимизация (2-3 дня)

#### День 6: Настройки пользователя
- [ ] Создание панели настроек в существующих настройках приложения
  - [ ] Управление API ключами
  - [ ] Выбор модели (MiniMax-Text-01 или DeepSeek-R1)
  - [ ] Настройка поведения при ошибках
- [ ] Реализация редактора промптов
  - [ ] Интерфейс для просмотра промптов
  - [ ] Возможность редактирования существующих промптов
  - [ ] Сброс до значений по умолчанию

#### День 7-8: Оптимизация и тестирование
- [ ] Оптимизация производительности
  - [ ] Минимизация задержек UI при запросах к API
  - [ ] Оптимизация хранения и извлечения суммаризаций
- [ ] Тщательное тестирование
  - [ ] Тестирование обработки ошибок
  - [ ] Тестирование с различными форматами книг
  - [ ] Проверка обработки больших глав

## Детали реализации

### 1. Структура папок и файлов

```
src/
├── services/
│   ├── llm/
│   │   ├── index.ts                     // Экспорты
│   │   ├── llm-provider.interface.ts    // Интерфейс LLMProvider
│   │   ├── llm-service-manager.ts       // Управление LLM сервисами
│   │   ├── providers/
│   │   │   ├── minimax-provider.ts      // Реализация Minimax
│   │   │   └── ...                      // Будущие провайдеры
│   │   └── types.ts                     // Общие типы
│   ├── chapter-extractor/
│   │   ├── index.ts
│   │   └── chapter-extractor.ts         // Извлечение текста главы
│   ├── summary-storage/
│   │   ├── index.ts
│   │   ├── summary-storage.ts           // SQLite хранилище
│   │   └── models.ts                    // Типы данных
│   └── prompt-manager/
│       ├── index.ts
│       ├── prompt-manager.ts            // Управление промптами
│       ├── default-prompts/
│       │   ├── ru.json                  // Русские промпты
│       │   └── en.json                  // Английские промпты (в будущем)
│       └── types.ts                     // Типы промптов
├── components/
│   ├── ai-assistant/
│   │   ├── index.ts
│   │   ├── ai-floating-button.tsx       // Модификация плавающей кнопки
│   │   ├── ai-options-menu.tsx          // Меню опций
│   │   └── chapter-summary.tsx          // Отображение суммаризации
│   └── settings/
│       ├── llm-settings.tsx             // Настройки LLM
│       └── prompt-editor.tsx            // Редактор промптов
└── config/
    └── llm-config.ts                    // Конфигурация LLM
```

### 2. Модель данных SQLite

```sql
-- Схема базы данных
CREATE TABLE chapter_summaries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id TEXT NOT NULL,               -- Уникальный идентификатор книги
    chapter_id TEXT NOT NULL,            -- Уникальный идентификатор главы
    chapter_title TEXT NOT NULL,         -- Читаемое название главы
    model TEXT NOT NULL,                 -- Используемая модель (напр. "MiniMax-Text-01")
    prompt_id TEXT NOT NULL,             -- Ссылка на используемый шаблон промпта
    prompt_text TEXT NOT NULL,           -- Текст промпта
    summary TEXT NOT NULL,               -- Текст суммаризации
    created_at INTEGER NOT NULL,         -- Время создания (timestamp)
    tokens_used INTEGER NOT NULL,        -- Общее количество использованных токенов
    tokens_input INTEGER NOT NULL,       -- Количество входных токенов
    tokens_output INTEGER NOT NULL,      -- Количество выходных токенов
    language TEXT NOT NULL,              -- Язык суммаризации
    UNIQUE(book_id, chapter_id, model, prompt_id)
);

CREATE INDEX idx_chapter_summaries_lookup ON chapter_summaries(book_id, chapter_id);
```

### 3. Ключевые интерфейсы

```typescript
// llm-provider.interface.ts
export interface LLMProvider {
  generateSummary(text: string, options: LLMOptions): Promise<SummaryResult>;
  checkAPIKey(): Promise<boolean>;
  getModelInfo(): LLMModelInfo;
  getAvailableModels(): string[];
}

// types.ts
export interface LLMOptions {
  model: string;
  prompt: PromptTemplate;
  maxTokens?: number;
  temperature?: number;
  language?: string;
}

export interface SummaryResult {
  summary: string;
  tokensUsed: number;
  tokensInput: number;
  tokensOutput: number;
  model: string;
  usedFallback?: boolean;
  originalModel?: string;
  fallbackModel?: string;
}

export interface LLMModelInfo {
  id: string;
  name: string;
  contextWindow: number;
  capabilities: string[];
  pricing?: {
    inputTokens: number;  // per 1M tokens
    outputTokens: number; // per 1M tokens
  };
}

// prompt-manager/types.ts
export interface PromptTemplate {
  id: string;
  name: string;
  system_message: string;
  user_template: string;
  parameters: {
    temperature: number;
    max_tokens: number;
    // другие параметры модели
  };
}
```

### 4. Интеграция с существующим кодом

Мы будем интегрироваться с существующим кодом Koodo Reader через следующие точки:

#### Извлечение текста главы

```typescript
// chapter-extractor.ts
export class ChapterExtractor {
  async extractCurrentChapter(htmlBook: HtmlBook): Promise<ChapterContent> {
    // Используем существующие методы Koodo Reader для получения текущей главы
    const rendition = htmlBook.rendition;
    const position = rendition.getPosition();
    const chapterIndex = position.chapterIndex;
    const chapterTitle = position.chapterTitle;
    const chapterId = htmlBook.flattenChapters[chapterIndex].id;
    
    // Извлекаем текст главы
    const content = await this.extractChapterText(rendition, chapterIndex);
    
    return {
      bookId: htmlBook.key,
      chapterId,
      chapterTitle,
      content,
      index: chapterIndex
    };
  }
  
  private async extractChapterText(rendition: any, chapterIndex: number): Promise<string> {
    // Получаем документ главы
    const chapterDoc = rendition.getChapterDoc()[chapterIndex];
    
    // Используем имеющиеся методы для извлечения текста
    // Если нет прямого метода, можем использовать DOM для извлечения
    // текстового содержимого из документа главы
    return this.extractTextFromDoc(chapterDoc);
  }
  
  private extractTextFromDoc(doc: any): string {
    // Извлечение чистого текста из HTML документа
    // Удаление лишних пробелов, форматирования и т.д.
    // ...
  }
}
```

#### Модификация плавающей кнопки AI

```typescript
// ai-floating-button.tsx
import React, { useState } from 'react';
import AiOptionsMenu from './ai-options-menu';

const AiFloatingButton: React.FC = () => {
  const [showOptions, setShowOptions] = useState(false);
  
  const handleClick = () => {
    setShowOptions(!showOptions);
  };
  
  return (
    <div className="ai-floating-button-container">
      <button 
        className="ai-floating-button" 
        onClick={handleClick}
      >
        AI
      </button>
      
      {showOptions && (
        <AiOptionsMenu onClose={() => setShowOptions(false)} />
      )}
    </div>
  );
};

export default AiFloatingButton;
```

```typescript
// ai-options-menu.tsx
import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Trans } from 'react-i18next';

interface AiOptionsMenuProps {
  onClose: () => void;
}

const AiOptionsMenu: React.FC<AiOptionsMenuProps> = ({ onClose }) => {
  const dispatch = useDispatch();
  const htmlBook = useSelector((state: any) => state.reader.htmlBook);
  
  const handleSummarizeChapter = () => {
    dispatch(actions.summarizeCurrentChapter(htmlBook));
    onClose();
  };
  
  return (
    <div className="ai-options-menu">
      <div className="ai-option" onClick={handleSummarizeChapter}>
        <span className="ai-option-icon">📝</span>
        <span className="ai-option-text">
          <Trans>Summarize Chapter</Trans>
        </span>
      </div>
      
      {/* Другие опции AI в будущем */}
      
      <div className="ai-option-close" onClick={onClose}>
        <Trans>Cancel</Trans>
      </div>
    </div>
  );
};

export default AiOptionsMenu;
```

### 5. Redux действия и редьюсеры

```typescript
// actions.ts
export const summarizeCurrentChapter = (htmlBook) => async (dispatch, getState) => {
  try {
    dispatch({ type: 'CHAPTER_SUMMARY_REQUEST' });
    
    const state = getState();
    const llmConfig = state.config.llm;
    const llmService = new LLMServiceManager(llmConfig);
    const chapterExtractor = new ChapterExtractor();
    const summaryStorage = new SummaryStorage();
    const promptManager = new PromptManager();
    
    // Получаем текущий выбранный промпт
    const promptId = llmConfig.defaultPromptId || 'quick_summary';
    const prompt = promptManager.getPrompt(promptId);
    
    // Извлекаем текст главы
    const chapterContent = await chapterExtractor.extractCurrentChapter(htmlBook);
    
    // Проверяем, есть ли уже суммаризация в кэше
    const cachedSummary = await summaryStorage.getSummary(
      chapterContent.bookId,
      chapterContent.chapterId,
      promptId
    );
    
    if (cachedSummary) {
      dispatch({
        type: 'CHAPTER_SUMMARY_SUCCESS',
        payload: cachedSummary,
        fromCache: true
      });
      return;
    }
    
    // Генерируем новую суммаризацию
    const summaryResult = await llmService.generateSummary(
      chapterContent.content,
      {
        model: llmConfig.model || 'MiniMax-Text-01',
        prompt,
        language: 'ru'
      }
    );
    
    // Сохраняем результат
    const summary = {
      bookId: chapterContent.bookId,
      chapterId: chapterContent.chapterId,
      chapterTitle: chapterContent.chapterTitle,
      model: summaryResult.model,
      promptId,
      promptText: JSON.stringify(prompt),
      summary: summaryResult.summary,
      createdAt: Date.now(),
      tokensUsed: summaryResult.tokensUsed,
      tokensInput: summaryResult.tokensInput,
      tokensOutput: summaryResult.tokensOutput,
      language: 'ru'
    };
    
    await summaryStorage.saveSummary(summary);
    
    dispatch({
      type: 'CHAPTER_SUMMARY_SUCCESS',
      payload: summary,
      fromCache: false
    });
  } catch (error) {
    dispatch({
      type: 'CHAPTER_SUMMARY_FAILURE',
      error: error.message
    });
  }
};

// reducer.ts
const initialState = {
  summary: null,
  loading: false,
  error: null,
  fromCache: false
};

export default function summaryReducer(state = initialState, action) {
  switch (action.type) {
    case 'CHAPTER_SUMMARY_REQUEST':
      return {
        ...state,
        loading: true,
        error: null
      };
    case 'CHAPTER_SUMMARY_SUCCESS':
      return {
        ...state,
        summary: action.payload,
        loading: false,
        error: null,
        fromCache: action.fromCache
      };
    case 'CHAPTER_SUMMARY_FAILURE':
      return {
        ...state,
        loading: false,
        error: action.error
      };
    default:
      return state;
  }
}
```

## План тестирования

1. **Юнит-тесты**
   - Тестирование извлечения текста главы
   - Тестирование работы с промптами
   - Тестирование обработки ошибок API

2. **Интеграционные тесты**
   - Интеграция между компонентами UI и сервисами
   - Корректное хранение и извлечение суммаризаций

3. **Ручное тестирование**
   - Проверка работы с книгами разных форматов
   - Проверка обработки ошибок API
   - Проверка работы с различными промптами
   - Тестирование производительности с длинными главами

## Риски и их снижение

1. **Ограничения API**
   - Риск: Превышение лимитов API или проблемы с доступом
   - Снижение: Реализация надежной обработки ошибок и механизма повторных попыток

2. **Обработка длинных глав**
   - Риск: Некоторые главы могут превышать максимальный размер контекста
   - Снижение: Реализация разделения текста на части и объединения результатов

3. **Производительность UI**
   - Риск: Задержки UI при обработке длинных запросов
   - Снижение: Использование асинхронной обработки и индикаторов прогресса

4. **Качество суммаризации**
   - Риск: Некачественные или неточные суммаризации
   - Снижение: Тщательная разработка промптов и возможность их настройки пользователем 