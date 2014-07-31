# -*- encoding : utf-8 -*-

Angenommen(/^ich habe eine offene Bestellung mit Modellen$/) do
  FactoryGirl.create(:contract_with_lines,
                     inventory_pool: @current_user.inventory_pools.sample,
                     user: @current_user,
                     status: :unsubmitted,
                     lines_count: rand(3..10))
end

Angenommen(/^die Bestellung Timeout ist (\d+) Minuten$/) do |arg1|
  expect(Contract::TIMEOUT_MINUTES).to eq arg1.to_i
end

#######################################################################

Wenn(/^ich ein Modell der Bestellung hinzufüge$/) do
  @inventory_pool = @current_user.inventory_pools.find_by_name("A-Ausleihe")
  @current_user.get_unsubmitted_contract(@inventory_pool).contract_lines << (@new_contract_line = FactoryGirl.create(:contract_line, :contract => @current_user.get_unsubmitted_contract(@inventory_pool)))
  expect(@new_contract_line.reload.available?).to be true
end

Wenn(/^ich dasselbe Modell einer Bestellung hinzufüge$/) do
  contract = @inventory_pool.contracts.submitted.sample
  (@new_contract_line.maximum_available_quantity + 1).times do
    contract.contract_lines << FactoryGirl.create(:contract_line,
                                                  :contract => contract,
                                                  :start_date => @new_contract_line.start_date,
                                                  :end_date => @new_contract_line.end_date,
                                                  :model_id => @new_contract_line.model_id)
  end
end

Wenn(/^die maximale Anzahl der Gegenstände überschritten ist$/) do
  expect(@new_contract_line.reload.available?).to be false
end

Dann(/^wird die Bestellung nicht abgeschlossen$/) do
  @current_user.contracts.unsubmitted.each do |contract|
    expect(contract.status).to eq :unsubmitted
  end
end

Dann(/^ich erhalte eine Fehlermeldung$/) do
  find(".error", match: :first)
end

#######################################################################

Wenn(/^ich länger als (\d+) Minuten keine Aktivität ausgeführt habe$/) do |arg1|
  @current_user.contracts.unsubmitted.each do |contract|
    contract.update_attributes updated_at: Time.now - (arg1.to_i + 1).minutes if (Time.now - contract.updated_at) <= arg1.to_i.minutes
  end
end

Angenommen(/^ein Modell ist nicht verfügbar$/) do
  line = @current_user.contracts.unsubmitted.flat_map(&:lines).sample
  (line.maximum_available_quantity + 1).times do
    c = FactoryGirl.create(:contract,
                           :inventory_pool => line.inventory_pool)
    FactoryGirl.create(:item_line,
                       :contract => c,
                       :model => line.model,
                       :start_date => line.start_date,
                       :end_date => line.end_date)
  end
  expect(line.reload.available?).to be false
end

Angenommen(/^(\d+) Modelle sind nicht verfügbar$/) do |n|
  @current_user.contracts.unsubmitted.flat_map(&:lines).take(n.to_i).each do |line|
    (line.maximum_available_quantity + 1).times do
      c = FactoryGirl.create(:contract,
                             :inventory_pool => line.inventory_pool)
      FactoryGirl.create(:contract_line,
                         :contract => c,
                         :model => line.model,
                         :start_date => line.start_date,
                         :end_date => line.end_date)
    end
  end
  expect(@current_user.contracts.unsubmitted.flat_map(&:lines).select{|line| not line.available?}.length).to eq n.to_i
end

Wenn(/^ich eine Aktivität ausführe$/) do
  visit borrow_root_path
end

Dann(/^werde ich auf die Timeout Page geleitet$/) do
  expect(current_path).to eq borrow_order_timed_out_path
end

#######################################################################

Dann(/^werden die Modelle meiner Bestellung freigegeben$/) do
  expect(@current_user.contracts.unsubmitted.flat_map(&:lines).all? {|line| not line.inventory_pool.running_lines.detect{|l| l.id == line.id } }).to be true
end

Dann(/^bleiben die Modelle in der Bestellung blockiert$/) do
  expect(@current_user.contracts.unsubmitted.flat_map(&:lines).all? {|line| line.inventory_pool.running_lines.detect{|l| l.id == line.id } }).to be true
end

#######################################################################

Angenommen(/^alle Modelle verfügbar sind$/) do
  expect(@current_user.contracts.unsubmitted.flat_map(&:lines).all? {|line| line.available? }).to be true
end

Dann(/^kann man sein Prozess fortsetzen$/) do
  expect(current_path).to eq borrow_root_path
end

Dann(/^die Modelle werden blockiert$/) do
  step "bleiben die Modelle in der Bestellung blockiert"
end

Wenn(/^eine Rücknahme nur Optionen enthält$/) do
  @ip = @current_inventory_pool = @current_user.inventory_pools.where("access_rights.suspended_until IS NULL OR access_rights.suspended_until < ?", Date.today).first
  (@customer = @current_inventory_pool.users.find{|u| u.visits.take_back.count == 0}).should be
  visit manage_hand_over_path @current_inventory_pool, @customer
  step 'I add an option to the hand over by providing an inventory code and a date range'
  step 'the option is added to the hand over'
  step 'I click hand over'
  find('#purpose')
  find('#purpose').set 'text'
  step 'I click hand over inside the dialog'
  visit manage_take_back_path @current_inventory_pool, @customer
end

Dann(/^wird für diese Optionen keine Verfügbarkeit berechnet$/) do
  expect(find('#status').has_content? _('Availability loaded')).to be true
end
