-- Hiệu ứng 1: Đào (Excavate) 4 lá bài trên cùng
function s.tgtcfilter(c)
	return c:IsFaceup()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsOnField() and s.tgtcfilter(chkc) and chkc~=e:GetHandler() end
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=4 
		and Duel.IsExistingTarget(s.tgtcfilter,tp,LOCATION_ONFIELD,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.tgtcfilter,tp,LOCATION_ONFIELD,0,1,1,e:GetHandler())
	-- Thiết lập thông tin operation cho hệ thống EDOPro biết trước sẽ có lá bài được thêm vào tay hoặc đưa vào Mộ/Xyz
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,0,tp,LOCATION_DECK)
end

function s.excfilter(c)
	-- Lọc các lá bài thuộc set Sky Striker trong nhóm 4 lá được lật lên
	return c:IsSetCard(0x115)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not e:GetHandler():IsRelateToEffect(e) or not tc:IsRelateToEffect(e) then return end
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<4 then return end
	
	-- Lật 4 lá bài trên cùng của Deck
	Duel.ConfirmDecktop(tp,4)
	local g=Duel.GetDecktopGroup(tp,4)
	
	if #g>0 then
		-- Lọc các lá bài Sky Striker có thể tương tác được trong 4 lá lật ra
		local sg=g:Filter(s.excfilter,nil)
		
		-- Kiểm tra xem có quái thú Xyz "Sky Striker" hợp lệ trên sân để gắn nguyên liệu không
		local xyzg=Duel.GetMatchingGroup(function(c) return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x115) end,tp,LOCATION_MZONE,0,nil)
		
		if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
			-- Cho phép người chơi chọn 1 lá Sky Striker hợp lệ trong các lá đã lật
			local sc=sg:Select(tp,1,1,nil):GetFirst()
			
			local b1 = sc:IsAbleToHand()
			local b2 = #xyzg > 0
			local op = 0
			
			-- Hộp thoại lựa chọn: Thêm lên tay (0) hay Gắn làm nguyên liệu Xyz (1)
			if b1 and b2 then
				op=Duel.SelectOption(tp,1190,aux.Stringid(id,2))
			elseif b1 then
				op=0
			elseif b2 then
				op=1
			else
				op=99 -- Không thỏa mãn cả hai thì bỏ qua
			end
			
			if op==0 then
				Duel.SendtoHand(sc,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sc)
			elseif op==1 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
				local xyz_tc=xyzg:Select(tp,1,1,nil):GetFirst()
				-- Đưa trực tiếp lá bài từ nhóm lật vào làm nguyên liệu Xyz mà không bị kẹt bộ lọc cũ
				if xyz_tc then
					Duel.Overlay(xyz_tc,sc)
				end
			end
		end
		
		-- Sắp xếp/Xáo lại các lá bài không được chọn về lại Deck theo cơ chế chuẩn của game
		Duel.ShuffleDeck(tp)
	end
end