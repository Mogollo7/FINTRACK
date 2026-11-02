import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../viewmodels/expense_viewmodel.dart';
import 'widgets/add_expense_sheet.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddExpenseSheet(),
    );
  }

  void _editExpenseDialog(BuildContext context, Expense expense) {
    final amountController = TextEditingController(text: expense.amount.toStringAsFixed(0));
    final noteController = TextEditingController(text: expense.note);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modificar Gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto (\$)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Nota descriptiva'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final newAmt = double.tryParse(amountController.text) ?? expense.amount;
              final updated = expense.copyWith(
                amount: newAmt,
                note: noteController.text.trim(),
              );
              Provider.of<ExpenseViewModel>(context, listen: false).updateExpense(updated);
              Navigator.pop(ctx);
              HapticFeedback.lightImpact();
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar registro?'),
        content: const Text('Esta acción revertirá el monto de tu presupuesto acumulado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<ExpenseViewModel>(context, listen: false).deleteExpense(id);
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _changeBudgetDialog(BuildContext context, double currentBudget) {
    final controller = TextEditingController(text: currentBudget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Presupuesto Semanal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Límite en \$ COP',
            prefixIcon: Icon(Icons.account_balance_wallet),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final newBudget = double.tryParse(controller.text);
              if (newBudget != null && newBudget > 0) {
                Provider.of<ExpenseViewModel>(context, listen: false).updateBudget(newBudget);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ExpenseViewModel>(context);
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.savings, color: Colors.teal),
            const SizedBox(width: 8),
            const Text('FinTrack', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            // Badge de conectividad (Capacidad móvil nativa)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: vm.isOnline ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    vm.isOnline ? Icons.wifi : Icons.wifi_off,
                    size: 14,
                    color: vm.isOnline ? Colors.green.shade800 : Colors.deepOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    vm.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: vm.isOnline ? Colors.green.shade800 : Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurar presupuesto',
            onPressed: () => _changeBudgetDialog(context, vm.weeklyBudget),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentTabIndex == 0
              ? _buildDashboard(vm, currencyFormat)
              : _currentTabIndex == 1
                  ? _buildHistory(vm, currencyFormat)
                  : const ReportScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) {
          HapticFeedback.selectionClick();
          setState(() => _currentTabIndex = idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tablero',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.picture_as_pdf_outlined),
            selectedIcon: Icon(Icons.picture_as_pdf),
            label: 'Informe PDF',
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex != 2
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context),
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Registrar Gasto', style: TextStyle(color: Colors.white)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDashboard(ExpenseViewModel vm, NumberFormat fmt) {
    final progress = vm.budgetProgressPercentage;
    final progressColor = progress >= 1.0
        ? Colors.red
        : progress >= 0.8
            ? Colors.orange
            : Colors.teal;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 84.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta principal: Dinero Invisible
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'DINERO INVISIBLE (GASTO HORMIGA)',
                    style: TextStyle(fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fmt.format(vm.totalSpent),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: progressColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'de ${fmt.format(vm.weeklyBudget)} presupuestados esta semana',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    color: progressColor,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Restante: ${fmt.format(vm.remainingBudget)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(progress * 100).toInt()}% consumido',
                        style: TextStyle(color: progressColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Alerta reflexiva de fricción consciente
          if (vm.isNearOrExceedingBudget)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      progress >= 1.0
                          ? '¡Atención! Has superado tu presupuesto semanal de microgastos.'
                          : 'Cuidado: estás cerca de alcanzar tu tope de gastos hormiga semanal.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Tarjeta de Equivalencia Cotidiana Tangible
          Card(
            color: Colors.teal.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.teal, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Equivalencia Cotidiana',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vm.dynamicEquivalence,
                          style: TextStyle(fontSize: 13, color: Colors.teal.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Banner de Acceso Rápido al Informe Descargable en PDF (RF-12)
          Card(
            color: Colors.amber.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.picture_as_pdf, color: Colors.white),
              ),
              title: const Text('Informe Contable Descargable (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Descarga tu reporte de balance personal y gastos hormiga.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentTabIndex = 2);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Sección de Últimos Movimientos en el Tablero
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Últimos Gastos Registrados',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(() => _currentTabIndex = 1),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          if (vm.expenses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No hay gastos registrados aún.\nToca "Registrar Gasto" para ingresar tu primera hormiga.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...vm.expenses.take(4).map((e) => _buildExpenseTile(e, fmt)),
        ],
      ),
    );
  }

  Widget _buildHistory(ExpenseViewModel vm, NumberFormat fmt) {
    if (vm.expenses.isEmpty) {
      return const Center(
        child: Text(
          'No hay historial registrado.\nLos gastos guardados permanecerán aquí incluso al cerrar la app.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 84, top: 12, left: 12, right: 12),
      itemCount: vm.expenses.length,
      itemBuilder: (ctx, index) {
        final expense = vm.expenses[index];
        return _buildExpenseTile(expense, fmt);
      },
    );
  }

  Widget _buildExpenseTile(Expense expense, NumberFormat fmt) {
    final dateFormat = DateFormat('dd/MM - HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: const Icon(Icons.coffee, color: Colors.teal),
        ),
        title: Text(
          expense.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${dateFormat.format(expense.date)}${expense.note.isNotEmpty ? " • ${expense.note}" : ""}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (expense.photoPath != null)
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: Image.file(File(expense.photoPath!)),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(expense.photoPath!),
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            Text(
              '-${fmt.format(expense.amount)}',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') {
                  _editExpenseDialog(context, expense);
                } else if (val == 'delete') {
                  _confirmDelete(context, expense.id!);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
