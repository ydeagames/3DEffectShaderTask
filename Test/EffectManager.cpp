#include "pch.h"
#include "EffectManager.h"
#include <WICTextureLoader.h>
#include "BinaryFile.h"
#include "d3d11.h"
#include <Effects.h>
#include <Model.h>

using namespace DirectX::SimpleMath;
using namespace DirectX;

const std::vector<D3D11_INPUT_ELEMENT_DESC> EffectManager::INPUT_LAYOUT =
{
	{ "POSITION",	0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0 },
	{ "COLOR",		0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, sizeof(Vector3), D3D11_INPUT_PER_VERTEX_DATA, 0 },
	{ "TEXCOORD",	0, DXGI_FORMAT_R32G32_FLOAT, 0, sizeof(Vector3) + sizeof(Vector4), D3D11_INPUT_PER_VERTEX_DATA, 0 },
};
void EffectManager::Create(DX::DeviceResources * deviceResources, const wchar_t* name,int count)
{
	m_deviceResources = deviceResources;
	auto device = m_deviceResources->GetD3DDevice();

	//const wchar_t* name = L"Resources\\Textures\\image01.png";
	DirectX::CreateWICTextureFromFile(deviceResources->	GetD3DDevice(), name , nullptr, m_texture.GetAddressOf());
	DirectX::CreateWICTextureFromFile(deviceResources->GetD3DDevice(), L"Resources\\Textures\\floor.png", nullptr, m_texture2.GetAddressOf());

	// �R���p�C�����ꂽ�V�F�[�_�t�@�C����ǂݍ���
	BinaryFile VSData = BinaryFile::LoadFile(L"Resources/Shaders/ParticleVS.cso");
	BinaryFile GSData = BinaryFile::LoadFile(L"Resources/Shaders/ParticleGS.cso");
	BinaryFile PSData = BinaryFile::LoadFile(L"Resources/Shaders/ParticlePS.cso");

	device->CreateInputLayout(&INPUT_LAYOUT[0],
		INPUT_LAYOUT.size(),
		VSData.GetData(), VSData.GetSize(),
		m_inputLayout.GetAddressOf());
	// ���_�V�F�[�_�쐬
	if (FAILED(device->CreateVertexShader(VSData.GetData(), VSData.GetSize(), NULL, m_VertexShader.ReleaseAndGetAddressOf())))
	{// �G���[
		MessageBox(0, L"CreateVertexShader Failed.", NULL, MB_OK);
		return;
	}
	// �W�I���g���V�F�[�_�쐬
	if (FAILED(device->CreateGeometryShader(GSData.GetData(), GSData.GetSize(), NULL, m_GeometryShader.ReleaseAndGetAddressOf())))
	{// �G���[
		MessageBox(0, L"CreateGeometryShader Failed.", NULL, MB_OK);
		return;
	}
	// �s�N�Z���V�F�[�_�쐬
	if (FAILED(device->CreatePixelShader(PSData.GetData(), PSData.GetSize(), NULL, m_PixelShader.ReleaseAndGetAddressOf())))
	{// �G���[
		MessageBox(0, L"CreatePixelShader Failed.", NULL, MB_OK);
		return;
	}
	// �v���~�e�B�u�o�b�`�̍쐬
	m_batch = std::make_unique<PrimitiveBatch<VertexPositionColorTexture>>(m_deviceResources->GetD3DDeviceContext());

	m_states = std::make_unique<CommonStates>(device);



	D3D11_BUFFER_DESC bd;
	ZeroMemory(&bd, sizeof(bd));
	bd.Usage = D3D11_USAGE_DEFAULT;
	bd.ByteWidth = sizeof(ConstBuffer);
	bd.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
	bd.CPUAccessFlags = 0;
	device->CreateBuffer(&bd, nullptr, &m_CBuffer);
	m_fxFactory = std::make_unique<EffectFactory>(device);
	m_fxFactory->SetDirectory(L"Resources");

	m_model = Model::CreateFromCMO(device, L"Resources/cup.cmo", *m_fxFactory);

	for (int i = 0; i < count; i++) {
		MyEffect* effect = new MyEffect();
		m_effectList.push_back(effect);
	}
}
void EffectManager::Lost() {
	for (std::list<MyEffect*>::iterator itr = m_effectList.begin(); itr != m_effectList.end(); itr++)
	{
		delete (*itr);
	}
}
void EffectManager::Initialize(float life, DirectX::SimpleMath::Vector3 pos)
{
	int range = 100;
	for (std::list<MyEffect*>::iterator itr = m_effectList.begin(); itr != m_effectList.end(); itr++)
	{
		Vector3 vel = Vector3(((rand() % (range * 2)) - range)*0.1f / range, ((rand() % (range * 2)) - range)*0.1f / range, 0);
		while (vel.Length() < 0.0001f) 
		{
			vel = Vector3(((rand() % (range * 2)) - range)*0.1f / range, ((rand() % (range * 2)) - range)*0.1f / range, 0);
		}
		(*itr)->Initialize(life,pos,vel);
	}
	m_centerPosition = pos;
}
void EffectManager::InitializeNormal(float life, DirectX::SimpleMath::Vector3 pos)
{
	int range = 1000;
	for (std::list<MyEffect*>::iterator itr = m_effectList.begin(); itr != m_effectList.end(); itr++)
	{
		Vector3 vel = Vector3(((rand() % (range * 2)) - range)*0.1f / range, ((rand() % (range * 2)) - range)*0.1f / range, 0);
		vel.Normalize();
		vel *= 0.1f;
		(*itr)->Initialize(life, pos, vel);
	}
	m_centerPosition = pos;
}
void EffectManager::InitializeCorn(float life, DirectX::SimpleMath::Vector3 pos, DirectX::SimpleMath::Vector3 dir)
{
	Vector3 vel = Vector3::Zero;
	for (std::list<MyEffect*>::iterator itr = m_effectList.begin(); itr != m_effectList.end(); itr++)
	{
		vel.x += XMConvertToRadians(90);
		(*itr)->Initialize(life, pos, vel);
	}
	m_centerPosition = pos;
}
void EffectManager::Update(DX::StepTimer timer)
{
	m_timer = timer;
	for(std::list<MyEffect*>::iterator itr = m_effectList.begin(); itr != m_effectList.end();itr++)
	{
		(*itr)->Update(timer);
	}
}

void EffectManager::Render()
{
	auto context = m_deviceResources->GetD3DDeviceContext();



	m_vertex.clear();
	//�}�l�[�W���ŊǗ����Ă���G�t�F�N�g���C�e���[�^����
	for (auto itr = m_effectList.begin(); itr != m_effectList.end(); itr++)
	{
		//�G�t�F�N�g�̒��_�̍��W�Ƒ��x���擾����
		Vector3 pos = (*itr)->GetPosition();
		Vector3 vel = (*itr)->GetVelocity();

		{
			//�擾�������W��o�^����
			VertexPositionColorTexture vertex;
			//vertex = VertexPositionColorTexture(pos, Vector4(vel.x,vel.y,vel.z,1), Vector2(0.0f,3.0f));
			vertex = VertexPositionColorTexture(pos, Vector4::Zero, Vector2::Zero);
			m_vertex.push_back(vertex);
		}
	}

	//�S��ʃG�t�F�N�g

	Matrix  mat = Matrix::Identity;
	Draw(mat, mat, mat);

	//�|���S���G�t�F�N�g

	//Draw(m_billboardTranslation,m_view, m_proj);

}

void EffectManager::SetRenderState(DirectX::SimpleMath::Vector3 camera, DirectX::SimpleMath::Matrix view, DirectX::SimpleMath::Matrix proj)
{
	m_view = view;
	m_proj = proj;

	m_billboardTranslation = Matrix::CreateBillboard(m_centerPosition, camera, Vector3::UnitY);

	//�r���{�[�h�̌v�Z�ŗ��Ԃ�̂ŕ␳
	//Y����180�x��]����s��
	Matrix rev = Matrix::Identity;
	rev._11 = -1;
	rev._33 = -1;

	//�␳�s����ɂ����đ��ɉe�����Ȃ��悤�ɂ���
	m_billboardTranslation =rev * m_billboardTranslation;

}

void EffectManager::Draw(DirectX::SimpleMath::Matrix world, DirectX::SimpleMath::Matrix view, DirectX::SimpleMath::Matrix proj)
{
	auto context = m_deviceResources->GetD3DDeviceContext();

	//�萔�o�b�t�@�œn���l�̐ݒ�
	ConstBuffer cbuff;
	cbuff.matView = view.Transpose();
	cbuff.matProj = proj.Transpose();
	cbuff.matWorld = world.Transpose();
	//Time		x:�o�ߎ���(�g�[�^���b)	y:1F�̌o�ߎ���(�b�j	z:�����i�T�C���J�[�u�j w:���g�p�i�b��łP�j
	cbuff.Time = Vector4(m_timer.GetTotalSeconds(), m_timer.GetElapsedSeconds(), sinf(m_timer.GetTotalSeconds()), 1);

	//�萔�o�b�t�@�̓��e�X�V
	context->UpdateSubresource(m_CBuffer.Get(), 0, NULL, &cbuff, 0, 0);

	ID3D11BlendState* blendstate = m_states->NonPremultiplied();
	// �������菈��
	context->OMSetBlendState(blendstate, nullptr, 0xFFFFFFFF);
	// �[�x�o�b�t�@�͎Q�Ƃ̂�
	context->OMSetDepthStencilState(m_states->DepthRead(), 0);
	// �J�����O�͔����v���
	context->RSSetState(m_states->CullCounterClockwise());

	//�萔�o�b�t�@���V�F�[�_�ɓn���i�Ƃ肠����PS�͗v��Ȃ��̂ŃR�����g�A�E�g�j
	ID3D11Buffer* cb[1] = { m_CBuffer.Get() };
	//context->VSSetConstantBuffers(0, 1, cb);
	context->GSSetConstantBuffers(0, 1, cb);
	context->PSSetConstantBuffers(0, 1, cb);


	//�T���v���[�A�V�F�[�_�A�摜�����ꂼ��o�^
	ID3D11SamplerState* sampler[1] = { m_states->LinearWrap() };
	context->PSSetSamplers(0, 1, sampler);
	context->VSSetShader(m_VertexShader.Get(), nullptr, 0);
	context->GSSetShader(m_GeometryShader.Get(), nullptr, 0);
	context->PSSetShader(m_PixelShader.Get(), nullptr, 0);
	context->PSSetShaderResources(0, 1, m_texture.GetAddressOf());
	context->PSSetShaderResources(1, 1, m_texture2.GetAddressOf());

	//���̓��C�A�E�g�𔽉f
	context->IASetInputLayout(m_inputLayout.Get());

	//�o�b�`�ɒ��_����n��
	m_batch->Begin();
	//m_batch->DrawQuad(vertex[0], vertex[1], vertex[2], vertex[3]);
	m_batch->Draw(D3D11_PRIMITIVE_TOPOLOGY_POINTLIST, &m_vertex[0], m_vertex.size());
	m_batch->End();


	//���̃��f���ɉe�����o��\��������̂Ŏg���I�������V�F�[�_���O��
	context->VSSetShader(nullptr, nullptr, 0);
	context->GSSetShader(nullptr, nullptr, 0);
	context->PSSetShader(nullptr, nullptr, 0);
	


}

//���f�������e�N�X�`��(m_srv)�ɕ`�悷�鏈��
void EffectManager::RenderModel() 
{
	auto context = m_deviceResources->GetD3DDeviceContext();

	D3D11_TEXTURE2D_DESC texDesc;
	m_deviceResources->GetRenderTarget()->GetDesc(&texDesc);
	texDesc.Format = DXGI_FORMAT_R8G8B8A8_TYPELESS;
	texDesc.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
	m_deviceResources->GetD3DDevice()->CreateTexture2D(&texDesc, NULL, m_capture.ReleaseAndGetAddressOf());

	// �����_�[�^�[�Q�b�g�r���[�̐ݒ�
	D3D11_RENDER_TARGET_VIEW_DESC rtvDesc;
	memset(&rtvDesc, 0, sizeof(rtvDesc));
	rtvDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
	rtvDesc.ViewDimension = D3D11_RTV_DIMENSION_TEXTURE2D;
	// �����_�[�^�[�Q�b�g�r���[�̐���
	m_deviceResources->GetD3DDevice()->CreateRenderTargetView(m_capture.Get(), &rtvDesc, &m_rtv);

	//�V�F�[�_���\�[�X�r���[�̐ݒ�
	D3D11_SHADER_RESOURCE_VIEW_DESC srvDesc;
	ZeroMemory(&srvDesc, sizeof(srvDesc));
	srvDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
	srvDesc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
	srvDesc.Texture2D.MostDetailedMip = 0;
	srvDesc.Texture2D.MipLevels = texDesc.MipLevels;

	//�����_�[�^�[�Q�b�g�r���[,�[�x�r���[���擾�i��Ō��ɖ߂����߁j
	ID3D11RenderTargetView* defaultRTV = m_deviceResources->GetRenderTargetView();
	ID3D11DepthStencilView* pDSV = m_deviceResources->GetDepthStencilView();

	//�w�i�F�̐ݒ�i�A���t�@���O�ɂ���ƃI�u�W�F�N�g�̂ݕ\���j
	float clearColor[4] = { 1.0f, 1.0f, 1.0f, 0.0f };

	//�����_�[�^�[�Q�b�g�r���[���Z�b�g���A����������
	context->OMSetRenderTargets(1, m_rtv.GetAddressOf(), pDSV);
	context->ClearRenderTargetView(m_rtv.Get(), clearColor);
	context->ClearDepthStencilView(pDSV, D3D11_CLEAR_DEPTH, 1.0f, 0);

	//----------------------------------------------------------------------------
	//�Ƃ肠�����̓����̂��߂ɉ�]
	static float rot = 0.0f;
	rot += 0.1f;

	//���f����`��
	m_model->Draw(m_deviceResources->GetD3DDeviceContext(), *m_states, Matrix::CreateRotationZ(rot), m_view, m_proj);

	//�`�悵����ʂ�m_srv�ɕۑ�
	auto hr = m_deviceResources->GetD3DDevice()->CreateShaderResourceView(
		m_capture.Get(), &srvDesc, m_srv.ReleaseAndGetAddressOf());

	//------------------------------------------------------------------
	//�ݒ�����Ƃɖ߂�
	clearColor[0] = 0.3f;
	clearColor[1] = 0.3f;
	context->OMSetRenderTargets(1, &defaultRTV, pDSV);
	context->ClearRenderTargetView(defaultRTV, clearColor);
	context->ClearDepthStencilView(pDSV, D3D11_CLEAR_DEPTH, 1.0f, 0);


}