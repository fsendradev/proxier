package logger

import (
	"fmt"
	"log"
)

const (
	LevelError = 1
	LevelInfo  = 2
	LevelAccess = 3
	LevelDebug = 4
)

type Logger struct {
	level int
}

func New(level int) *Logger {
	return &Logger{level: level}
}

func (l *Logger) Error(format string, v ...interface{}) {
	if l.level >= LevelError {
		log.Output(2, fmt.Sprintf("[ERROR] "+format, v...))
	}
}

func (l *Logger) Info(format string, v ...interface{}) {
	if l.level >= LevelInfo {
		log.Output(2, fmt.Sprintf("[INFO] "+format, v...))
	}
}

func (l *Logger) Access(format string, v ...interface{}) {
	if l.level >= LevelAccess {
		log.Output(2, fmt.Sprintf("[ACCESS] "+format, v...))
	}
}

func (l *Logger) Debug(format string, v ...interface{}) {
	if l.level >= LevelDebug {
		log.Output(2, fmt.Sprintf("[DEBUG] "+format, v...))
	}
}
