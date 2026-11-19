import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'models/repository_model.dart';
import 'repository_manager.dart';

/// States for the Repository BLoC.

abstract class RepositoryState extends Equatable {
  const RepositoryState();

  @override
  List<Object?> get props => [];
}

class RepositoryInitial extends RepositoryState {
  const RepositoryInitial();
}

class RepositoryLoading extends RepositoryState {
  const RepositoryLoading();
}

class RepositoryLoaded extends RepositoryState {
  final List<RepositoryModel> repositories;
  final RepositoryModel activeRepository;

  const RepositoryLoaded({
    required this.repositories,
    required this.activeRepository,
  });

  @override
  List<Object?> get props => [repositories, activeRepository];
}

class RepositorySwitching extends RepositoryState {
  final RepositoryModel previousRepository;
  final RepositoryModel targetRepository;

  const RepositorySwitching({
    required this.previousRepository,
    required this.targetRepository,
  });

  @override
  List<Object?> get props => [previousRepository, targetRepository];
}

class RepositoryError extends RepositoryState {
  final String message;
  final RepositoryModel? currentRepository;

  const RepositoryError(
    this.message, {
    this.currentRepository,
  });

  @override
  List<Object?> get props => [message, currentRepository];
}

/// Events for the Repository BLoC.

abstract class RepositoryEvent extends Equatable {
  const RepositoryEvent();

  @override
  List<Object?> get props => [];
}

class RepositoryLoadRequested extends RepositoryEvent {
  const RepositoryLoadRequested();
}

class RepositoryAdded extends RepositoryEvent {
  final RepositoryModel repository;

  const RepositoryAdded(this.repository);

  @override
  List<Object?> get props => [repository];
}

class RepositoryUpdated extends RepositoryEvent {
  final String id;
  final RepositoryModel repository;

  const RepositoryUpdated(this.id, this.repository);

  @override
  List<Object?> get props => [id, repository];
}

class RepositoryDeleted extends RepositoryEvent {
  final String id;

  const RepositoryDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

class RepositoryEnabled extends RepositoryEvent {
  final String id;

  const RepositoryEnabled(this.id);

  @override
  List<Object?> get props => [id];
}

class RepositoryDisabled extends RepositoryEvent {
  final String id;

  const RepositoryDisabled(this.id);

  @override
  List<Object?> get props => [id];
}

class RepositorySwitchRequested extends RepositoryEvent {
  final String repositoryId;

  const RepositorySwitchRequested(this.repositoryId);

  @override
  List<Object?> get props => [repositoryId];
}

class RepositoryDefaultSet extends RepositoryEvent {
  final String id;

  const RepositoryDefaultSet(this.id);

  @override
  List<Object?> get props => [id];
}

class RepositoryTestRequested extends RepositoryEvent {
  final RepositoryModel repository;

  const RepositoryTestRequested(this.repository);

  @override
  List<Object?> get props => [repository];
}

class RepositoryCacheCleared extends RepositoryEvent {
  final String id;

  const RepositoryCacheCleared(this.id);

  @override
  List<Object?> get props => [id];
}

/// BLoC for managing repository state and operations.
class RepositoryBloc extends Bloc<RepositoryEvent, RepositoryState> {
  final RepositoryManager _manager;

  RepositoryBloc(this._manager) : super(const RepositoryInitial()) {
    on<RepositoryLoadRequested>(_onLoadRequested);
    on<RepositoryAdded>(_onAdded);
    on<RepositoryUpdated>(_onUpdated);
    on<RepositoryDeleted>(_onDeleted);
    on<RepositoryEnabled>(_onEnabled);
    on<RepositoryDisabled>(_onDisabled);
    on<RepositorySwitchRequested>(_onSwitchRequested);
    on<RepositoryDefaultSet>(_onDefaultSet);
    on<RepositoryTestRequested>(_onTestRequested);
    on<RepositoryCacheCleared>(_onCacheCleared);

    // Listen to manager changes
    _manager.addListener(_onManagerChanged);
  }

  Future<void> _onLoadRequested(
    RepositoryLoadRequested event,
    Emitter<RepositoryState> emit,
  ) async {
    emit(const RepositoryLoading());
    try {
      await _manager.loadFromStorage();
      emit(
        RepositoryLoaded(
          repositories: _manager.repositories,
          activeRepository: _manager.activeRepository,
        ),
      );
    } catch (e) {
      emit(RepositoryError(e.toString()));
    }
  }

  Future<void> _onAdded(
    RepositoryAdded event,
    Emitter<RepositoryState> emit,
  ) async {
    try {
      await _manager.addRepository(event.repository);
      emit(
        RepositoryLoaded(
          repositories: _manager.repositories,
          activeRepository: _manager.activeRepository,
        ),
      );
    } catch (e) {
      emit(RepositoryError(e.toString()));
    }
  }

  Future<void> _onUpdated(
    RepositoryUpdated event,
    Emitter<RepositoryState> emit,
  ) async {
    try {
      await _manager.updateRepository(event.id, event.repository);
      emit(
        RepositoryLoaded(
          repositories: _manager.repositories,
          activeRepository: _manager.activeRepository,
        ),
      );
    } catch (e) {
      emit(RepositoryError(e.toString()));
    }
  }

  Future<void> _onDeleted(
    RepositoryDeleted event,
    Emitter<RepositoryState> emit,
  ) async {
    try {
      await _manager.deleteRepository(event.id);
      emit(
        RepositoryLoaded(
          repositories: _manager.repositories,
          activeRepository: _manager.activeRepository,
        ),
      );
    } catch (e) {
      emit(
        RepositoryError(
          e.toString(),
          currentRepository: _manager.activeRepository,
        ),
      );
    }
  }

  Future<void> _onEnabled(
    RepositoryEnabled event,
    Emitter<RepositoryState> emit,
  ) async {
    try {
      await _manager.enableRepository(event.id);
      emit(
        RepositoryLoaded(
          repositories: _manager.repositories,
          activeRepository: _manager.activeRepository,
        ),
      );
    } catch (e) {
      emit(RepositoryError(e.toString()));
    }
  }

  Future<void> _onDisabled(
    RepositoryDisabled event,
    Emitter<RepositoryState> emit,
  ) async {
    try {
      await _manager.disableRepository(event.id);
      emit(
        RepositoryLoaded(
          repositories: _manager.repositories,
          activeRepository: _manager.activeRepository,
        ),
      );
    } catch (e) {
      emit(
        RepositoryError(
          e.toString(),
          currentRepository: _manager.activeRepository,
        ),
      );
    }
  }

  Future<void> _onSwitchRequested(
    RepositorySwitchRequested event,
    Emitter<RepositoryState> emit,
  ) async {
    try {
      final targetRepo = _manager.getRepository(event.repositoryId);
      if (targetRepo == null) {
        emit(RepositoryError('Repository not found'));
        return;
      }

      emit(
        RepositorySwitching(
          previousRepository: _manager.activeRepository,
          targetRepository: targetRepo,
        ),
      );

      await _manager.switchRepository(event.repositoryId);

      emit(
        RepositoryLoaded(
          repositories: _manager.repositories,
          activeRepository: _manager.activeRepository,
        ),
      );
    } catch (e) {
      emit(
        RepositoryError(
          e.toString(),
          currentRepository: _manager.activeRepository,
        ),
      );
    }
  }

  Future<void> _onDefaultSet(
    RepositoryDefaultSet event,
    Emitter<RepositoryState> emit,
  ) async {
    try {
      await _manager.setDefaultRepository(event.id);
      emit(
        RepositoryLoaded(
          repositories: _manager.repositories,
          activeRepository: _manager.activeRepository,
        ),
      );
    } catch (e) {
      emit(RepositoryError(e.toString()));
    }
  }

  Future<void> _onTestRequested(
    RepositoryTestRequested event,
    Emitter<RepositoryState> emit,
  ) async {
    try {
      final result = await _manager.testRepository(event.repository);
      if (!result.success) {
        emit(
          RepositoryError(
            result.errorMessage ?? 'Connection test failed',
            currentRepository: _manager.activeRepository,
          ),
        );
      }
    } catch (e) {
      emit(RepositoryError(e.toString()));
    }
  }

  Future<void> _onCacheCleared(
    RepositoryCacheCleared event,
    Emitter<RepositoryState> emit,
  ) async {
    try {
      await _manager.clearRepositoryCache(event.id);
      emit(
        RepositoryLoaded(
          repositories: _manager.repositories,
          activeRepository: _manager.activeRepository,
        ),
      );
    } catch (e) {
      emit(RepositoryError(e.toString()));
    }
  }

  void _onManagerChanged() {
    // Emit an updated state when the manager notifies
    add(const RepositoryLoadRequested());
  }

  @override
  Future<void> close() {
    _manager.removeListener(_onManagerChanged);
    return super.close();
  }
}
