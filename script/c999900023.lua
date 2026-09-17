-- Homulily the Magica Puella Witch
-- ID: 999900023
local s,id=GetID()

local SET_MAGICA		  = 0x654
local SET_PUELLA_WITCH  = 0x1654
local CARD_HOMURA_RITUAL  = 999900020
local CARD_HOMURA_LINK  = 999900024
local CARD_EVENT_HORIZON  = 999900021
local TOKEN_GRIEF_SEED  = 999900006

s.listed_series={SET_MAGICA, SET_PUELLA_WITCH}
s.listed_names={CARD_HOMURA_RITUAL, CARD_HOMURA_LINK, CARD_EVENT_HORIZON, TOKEN_GRIEF_SEED}

function s.initial_effect(c)
	-- Điều kiện triệu hồi Xyz tiêu chuẩn: 2+ quái thú "Magica" Level 12
	Xyz.AddProcedure(c, aux.FilterBoolFunction(Card.IsSetCard, SET_MAGICA), 12, 2, nil, nil, Xyz.InfiniteMats)
	c:EnableReviveLimit()

	-- 1. Triệu hồi Đặc biệt từ Extra Deck bằng cách chọn 1 Homura Ritual/Link dưới GY làm nguyên liệu
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROCEDURE)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.xyzspcon)
	e1:SetTarget(s.xyzsptg)
	e1:SetOperation(s.xyzspop)
	c:RegisterEffect(e1)

	-- 2. Hiệu ứng liên tục: Khi lá này có nguyên liệu, quái thú "Magica" ngửa mặt không chịu ảnh hưởng bởi hiệu ứng card đối thủ
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetCondition(s.immcon)
	e2:SetTarget(s.immtg)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)

	-- 3. Ignition Effect: Trả 500 LP -> Search "TIME REWIND: THE MAGICA EVENT HORIZON" từ Deck lên tay
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCost(s.thcost)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

	-- 4. Quick Effect: Khi đối thủ kích hoạt lá bài/hiệu ứng -> gỡ 1 nguyên liệu về tay -> Đổi hiệu ứng đó của đối thủ
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_DESTROY+CATEGORY_DRAW)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.chcon)
	e4:SetCost(s.chcost)
	e4:SetTarget(s.chtg)
	e4:SetOperation(s.chop)
	c:RegisterEffect(e4)

	-- 5. Khi lá này bị gửi xuống GY: Special Summon 1 "Grief Seed" Token
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_TO_GRAVE)
	e5:SetTarget(s.tokentg)
	e5:SetOperation(s.tokenop)
	c:RegisterEffect(e5)
end

--------------------------------------------------------------------------------
-- 1. SPECIAL XYZ SUMMON PROCEDURE LOGIC
--------------------------------------------------------------------------------
function s.xyzfilter(c)
	return (c:IsCode(CARD_HOMURA_RITUAL) or c:IsCode(CARD_HOMURA_LINK)) and c:IsCanBeXyzMaterial()
end

function s.xyzspcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_GRAVE,0,1,nil)
end

function s.xyzsptg(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end

function s.xyzspop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	c:SetMaterial(g)
	Duel.Overlay(c,g)
	g:DeleteGroup()
end

--------------------------------------------------------------------------------
-- 2. IMMUNITY LOGIC
--------------------------------------------------------------------------------
function s.immcon(e)
	return e:GetHandler():GetOverlayCount()>0
end

function s.immtg(e,c)
	return c:IsFaceup() and c:IsSetCard(SET_MAGICA)
end

function s.efilter(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

--------------------------------------------------------------------------------
-- 3. SEARCH SPELL LOGIC
--------------------------------------------------------------------------------
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,500) end
	Duel.PayLPCost(tp,500)
end

function s.thfilter(c)
	return c:IsCode(CARD_EVENT_HORIZON) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------------------------------------------------------------
-- 4. CHANGE OPPONENT'S EFFECT LOGIC
--------------------------------------------------------------------------------
function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp
end

function s.chcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:GetOverlayGroup():IsExists(Card.IsAbleToHand,1,nil) end
	local g=c:GetOverlayGroup():Filter(Card.IsAbleToHand,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local sg=g:Select(tp,1,1,nil)
	Duel.SendtoHand(sg,REASON_COST)
end

function s.chtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.chop(e,tp,eg,ep,ev,re,r,rp)
	local g=Group.CreateGroup()
	Duel.ChangeTargetCard(ev,g)
	Duel.ChangeChainOperation(ev,s.repop)
end

function s.magicacardfilter(c)
	return c:IsSetCard(SET_MAGICA)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.magicacardfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		Duel.Draw(1-tp,1,REASON_EFFECT)
	end
end

--------------------------------------------------------------------------------
-- 5. TOKEN ON SENT TO GY LOGIC
--------------------------------------------------------------------------------
function s.tokentg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
end

function s.tokenop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 
		or not Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_GRIEF_SEED,0,TYPES_TOKEN+TYPE_MONSTER,300,300,1,RACE_SPELLCASTER,ATTRIBUTE_DARK) then return end
	local token=Duel.CreateToken(tp,TOKEN_GRIEF_SEED)
	Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
end