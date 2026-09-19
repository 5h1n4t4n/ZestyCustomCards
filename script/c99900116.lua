--Zhao Yun – Vanguard of Valor
local s,id=GetID()
s.listed_series={0xb4c}
function s.initial_effect(c)
	-- Link Summon: 2+ Quái thú Hiệu ứng (kèm hàm kiểm tra nhóm s.lcheck)
	Link.AddProcedure(c, aux.FilterBoolFunction(Card.IsType, TYPE_EFFECT), 2, 99, s.lcheck)
	c:EnableReviveLimit()
	
	--When Link Summoned: Return 1 opponent's monster to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	e1:SetCountLimit(1,id)
	c:RegisterEffect(e1)
	
	--Monsters this card points to cannot activate their effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_DISABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetTarget(s.distg)
	c:RegisterEffect(e2)
	
	--Spell/Trap you control cannot be destroyed (once per card)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_ONFIELD,0)
	e3:SetTarget(s.indtg)
	e3:SetValue(s.indct)
	c:RegisterEffect(e3)
end

--Link check: Must include at least 1 "Mecha Three Kingdoms" monster
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,0xb4c)
end

--Effect 1: Return 1 opponent's monster when Link Summoned
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsAbleToHand() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToHand,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end

--Effect 2: Monsters this card points to cannot activate effects
function s.distg(e,c)
	local handler=e:GetHandler()
	return handler:GetLinkedGroup():IsContains(c)
end

--Effect 3: S/T you control cannot be destroyed (once per card)
function s.indtg(e,c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsFaceup()
end

function s.indct(e,re,r,rp)
	if (r&REASON_EFFECT)~=0 then
		return 1
	else
		return 0
	end
end